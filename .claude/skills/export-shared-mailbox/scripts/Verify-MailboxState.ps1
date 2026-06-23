<#
.SYNOPSIS
    Fase 0 del runbook export-shared-mailbox: verifica preliminare in SOLA LETTURA delle caselle
    Exchange Online da esportare. Nessun comando di modifica o cancellazione.

.DESCRIPTION
    Per ogni casella indicata raccoglie dimensioni e conteggi di primaria e archivio online, e lo
    stato hold/retention/quote (decisivo per la futura fase di svuotamento, non per l'export).
    Controlla anche le retention policy a livello tenant. Salva un transcript come report.

    AUTENTICAZIONE (ADR-003, rivisto):
    - Interattiva (default): apre il login Microsoft. Il broker WAM richiede una FINESTRA, quindi
      lo script va eseguito in una vera finestra PowerShell / Windows Terminal, NON da host senza
      window handle (es. il prefisso "!" di Claude Code), altrimenti fallisce con
      "A window handle must be configured". Il modulo ExchangeOnlineManagement 3.x NON espone un
      device-code flow.
    - App-only (headless/VM): se si passano -AppId e -CertificateThumbprint (+ -Organization),
      lo script si autentica senza interazione tramite un'app registrata in Entra ID con
      certificato. È la via corretta per l'esecuzione non presidiata.

.PARAMETER Mailboxes
    Indirizzi SMTP delle caselle da verificare. Default: le due caselle condivise Intrawelt.

.PARAMETER UserPrincipalName
    Account amministrativo per il login interattivo.

.PARAMETER AppId
    (App-only) Application (client) ID dell'app registrata in Entra ID con i permessi Exchange.

.PARAMETER CertificateThumbprint
    (App-only) Thumbprint del certificato associato all'app, presente nello store del computer.

.PARAMETER Organization
    (App-only) Dominio del tenant, es. intrawelt.onmicrosoft.com.

.PARAMETER ReportDir
    Cartella dove salvare il transcript di report. Default: export-locale\ del progetto (ignorato).

.EXAMPLE
    # Interattivo: ESEGUIRE IN UNA FINESTRA POWERSHELL REALE (non via "!")
    .\Verify-MailboxState.ps1

.EXAMPLE
    # Headless/VM (app-only con certificato)
    .\Verify-MailboxState.ps1 -AppId <guid> -CertificateThumbprint <thumb> -Organization intrawelt.onmicrosoft.com
#>
[CmdletBinding()]
param(
    [string[]]$Mailboxes = @('casella-a@intrawelt.com','casella-b@intrawelt.com'),
    [string]$UserPrincipalName = 'asopranzi@intrawelt.com',
    [string]$AppId,
    [string]$CertificateThumbprint,
    [string]$Organization = 'intrawelt.onmicrosoft.com',
    [string]$ReportDir
)

$ErrorActionPreference = 'Stop'

# Risolve la radice del progetto a partire dalla posizione dello script
# (.../<root>/.claude/skills/export-shared-mailbox/scripts/)
$projRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
if (-not $ReportDir) { $ReportDir = Join-Path $projRoot 'export-locale' }
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$report = Join-Path $ReportDir "fase0-verifica-$stamp.txt"
Start-Transcript -Path $report -Force | Out-Null

# App-only se vengono forniti sia AppId sia CertificateThumbprint; altrimenti interattivo
$appOnly   = $AppId -and $CertificateThumbprint
$authLabel = if ($appOnly) { "App-only ($AppId)" } else { 'Interattiva' }

Write-Host "== Connessione a Exchange Online (auth: $authLabel) ==" -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    throw "Modulo ExchangeOnlineManagement non installato. Eseguire: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
}
Import-Module ExchangeOnlineManagement

if ($appOnly) {
    Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Organization $Organization -ShowBanner:$false
} else {
    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false
}

try {
    foreach ($smtp in $Mailboxes) {
        Write-Host "`n================= $smtp =================" -ForegroundColor Green

        $mb = Get-EXOMailbox -Identity $smtp -PropertySets All -ErrorAction Stop

        Write-Host "-- Casella PRIMARIA --"
        Get-EXOMailboxStatistics -Identity $smtp |
            Select-Object DisplayName, ItemCount, TotalItemSize, TotalDeletedItemSize |
            Format-List | Out-Host

        if ($mb.ArchiveStatus -eq 'Active' -or $mb.ArchiveState -eq 'Local') {
            Write-Host "-- ARCHIVIO ONLINE --"
            Get-EXOMailboxStatistics -Identity $smtp -Archive |
                Select-Object DisplayName, ItemCount, TotalItemSize, TotalDeletedItemSize |
                Format-List | Out-Host
        } else {
            Write-Host "-- Nessun archivio online attivo --" -ForegroundColor Yellow
        }

        Write-Host "-- Stato HOLD / quote (decisivo per il futuro svuotamento, non per l'export) --"
        $mb | Select-Object DisplayName, RecipientTypeDetails, LitigationHoldEnabled,
                            ComplianceTagHoldApplied, InPlaceHolds, RetentionHoldEnabled,
                            AutoExpandingArchiveEnabled, ProhibitSendReceiveQuota,
                            ArchiveQuota, ArchiveWarningQuota |
            Format-List | Out-Host
    }

    Write-Host "`n== Retention policy a livello tenant (Security & Compliance) ==" -ForegroundColor Cyan
    try {
        if ($appOnly) {
            Connect-IPPSSession -AppId $AppId -CertificateThumbprint $CertificateThumbprint -Organization $Organization
        } else {
            Connect-IPPSSession -UserPrincipalName $UserPrincipalName
        }
        Get-RetentionCompliancePolicy |
            Select-Object Name, Enabled, Mode, ExchangeLocation |
            Format-Table -AutoSize | Out-Host
    } catch {
        Write-Warning "Impossibile leggere le retention policy: $($_.Exception.Message)"
    }
}
finally {
    Write-Host "`n== FINE verifica (sola lettura). Report: $report ==" -ForegroundColor Cyan
    Stop-Transcript | Out-Null
    try { Disconnect-ExchangeOnline -Confirm:$false } catch {}
}
