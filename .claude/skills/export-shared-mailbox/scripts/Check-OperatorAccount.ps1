<#
.SYNOPSIS
    Verifica in SOLA LETTURA se un account è idoneo a fare da operatore eDiscovery/export:
    tipo di casella (shared vs utente), sign-in abilitato, licenze, e appartenenza al gruppo
    di ruolo eDiscovery (Export). Scrive un report su file.

.DESCRIPTION
    Esegue tre connessioni interattive (Graph, Exchange Online, Security & Compliance) e raccoglie:
    - Graph: AccountEnabled, UserType, licenze assegnate (SKU mappate a nome leggibile).
    - Exchange Online: RecipientTypeDetails (UserMailbox / SharedMailbox / ...).
    - Security & Compliance: membri del gruppo di ruolo eDiscovery Manager.
    Produce un VERDETTO sull'usabilità come operatore. Nessuna scrittura sul tenant.

    DA ESEGUIRE IN UNA FINESTRA POWERSHELL REALE (il login interattivo / broker WAM richiede una
    finestra; non funziona da host headless). Verranno richiesti fino a tre login.

.PARAMETER Account
    Account da verificare. Default: it@intrawelt.com.

.PARAMETER RoleGroup
    Gruppo di ruolo da controllare. Default: 'eDiscovery Manager'.

.EXAMPLE
    .\Check-OperatorAccount.ps1
#>
[CmdletBinding()]
param(
    [string]$Account = 'it@intrawelt.com',
    [string]$RoleGroup = 'eDiscovery Manager'
)

$ErrorActionPreference = 'Continue'

$projRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$reportDir = Join-Path $projRoot 'export-locale'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report = Join-Path $reportDir 'operator-check.txt'
Start-Transcript -Path $report -Force | Out-Null

Write-Host "===== VERIFICA OPERATORE: $Account =====" -ForegroundColor Cyan

# Risultati raccolti
$accountEnabled = $null; $userType = $null; $licenses = @(); $recipType = $null; $inRole = $null

# --- 1) Microsoft Graph: sign-in e licenze ---
Write-Host "`n[1/3] Microsoft Graph (sign-in, licenze)..." -ForegroundColor Cyan
try {
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    Connect-MgGraph -Scopes 'User.Read.All','Organization.Read.All' -NoWelcome -ErrorAction Stop
    $u = Get-MgUser -UserId $Account -Property Id,DisplayName,UserPrincipalName,AccountEnabled,UserType,AssignedLicenses,Mail -ErrorAction Stop
    $accountEnabled = $u.AccountEnabled
    $userType = $u.UserType
    $skuMap = @{}
    try { Get-MgSubscribedSku -All | ForEach-Object { $skuMap[$_.SkuId] = $_.SkuPartNumber } } catch {}
    $licenses = @($u.AssignedLicenses | ForEach-Object { if ($skuMap[$_.SkuId]) { $skuMap[$_.SkuId] } else { $_.SkuId } })
    $licText = if ($licenses.Count -gt 0) { $licenses -join ', ' } else { '(nessuna)' }
    Write-Host ("  DisplayName     : {0}" -f $u.DisplayName)
    Write-Host ("  UPN             : {0}" -f $u.UserPrincipalName)
    Write-Host ("  AccountEnabled  : {0}" -f $accountEnabled)
    Write-Host ("  UserType        : {0}" -f $userType)
    Write-Host ("  Licenze         : {0}" -f $licText)
} catch {
    Write-Warning "Graph non disponibile o account non trovato: $($_.Exception.Message)"
}

# --- 2) Exchange Online: tipo di destinatario ---
Write-Host "`n[2/3] Exchange Online (tipo casella)..." -ForegroundColor Cyan
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    $r = Get-EXORecipient -Identity $Account -ErrorAction Stop
    $recipType = $r.RecipientTypeDetails
    Write-Host ("  RecipientTypeDetails : {0}" -f $recipType)
} catch {
    Write-Warning "Exchange Online non disponibile o destinatario non trovato: $($_.Exception.Message)"
}

# --- 3) Security & Compliance: ruolo eDiscovery ---
Write-Host "`n[3/3] Security & Compliance (ruolo $RoleGroup)..." -ForegroundColor Cyan
try {
    Connect-IPPSSession -ErrorAction Stop
    $members = Get-RoleGroupMember -Identity $RoleGroup -ErrorAction Stop
    $inRole = [bool]($members | Where-Object { $_.WindowsLiveID -eq $Account -or $_.PrimarySmtpAddress -eq $Account -or $_.Name -eq ($Account -split '@')[0] })
    Write-Host ("  Membri '$RoleGroup': {0}" -f (($members.Name) -join ', '))
    Write-Host ("  '$Account' è membro: {0}" -f $inRole)
} catch {
    Write-Warning "Security & Compliance non disponibile: $($_.Exception.Message)"
}

# --- VERDETTO ---
Write-Host "`n===== VERDETTO =====" -ForegroundColor Yellow
$blocchi = @()
if ($recipType -eq 'SharedMailbox')      { $blocchi += "è una SharedMailbox: il sign-in è disabilitato di default, NON può autenticarsi come operatore" }
if ($accountEnabled -eq $false)          { $blocchi += "AccountEnabled = False: l'accesso è bloccato" }
if (($licenses -join '') -eq '' -and $recipType -ne 'SharedMailbox') { $blocchi += "nessuna licenza assegnata (verificare che basti per eDiscovery)" }

if ($blocchi.Count -eq 0 -and $recipType) {
    Write-Host "IDONEO come operatore: l'account può autenticarsi." -ForegroundColor Green
    if ($inRole -eq $false) { Write-Host "  -> Manca solo l'appartenenza a '$RoleGroup': aggiungerlo (azione reversibile)." -ForegroundColor Yellow }
    elseif ($inRole) { Write-Host "  -> Già membro di '$RoleGroup'." -ForegroundColor Green }
} else {
    Write-Host "NON idoneo / da sistemare:" -ForegroundColor Red
    $blocchi | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host "`nReport salvato in: $report" -ForegroundColor Cyan
Stop-Transcript | Out-Null
try { Disconnect-ExchangeOnline -Confirm:$false } catch {}
try { Disconnect-MgGraph | Out-Null } catch {}
