<#
.SYNOPSIS
    Verifica la COMPLETEZZA di un export PST fatto da Outlook desktop, confrontando il numero di
    item presenti nei PST con i conteggi di riferimento della Fase 0. Sola lettura sui PST.

.DESCRIPTION
    Apre via Outlook COM ogni file .pst presente in -SourceDir, somma ricorsivamente gli item di
    tutte le cartelle e raggruppa i PST per casella in base al nome file (pattern -LabelMap).
    Per ogni casella confronta il totale contato con il totale atteso (-Expected) e produce un
    verdetto con delta assoluto e percentuale. Scrive un report transcript in export-locale\.

    Pensato per il metodo Outlook desktop (vedi ADR-007), in cui l'archivio online viene esportato
    a blocchi su piu' PST: lo script somma tutti i PST della stessa casella. Non confronta primaria
    e archivio separatamente, perche' i blocchi non rispettano quel confine; confronta il TOTALE
    casella (primaria + archivio) con il totale atteso di Fase 0.

    REQUISITI: Outlook classico (Win32) installato e un profilo MAPI configurato sulla macchina.
    NON il "nuovo Outlook" (privo di COM e di export PST). Lo script puo' girare con Outlook aperto
    o chiuso; se un PST e' gia' aperto in Outlook lo usa senza riaprirlo ne' rimuoverlo.

    TOLLERANZA: i conteggi di Fase 0 derivano da Get-MailboxStatistics/Get-MailboxFolderStatistics
    e includono elementi (Recoverable Items, cartelle di sistema) che l'export PST non riporta. Un
    export COMPLETO risultera' quindi tipicamente di POCO inferiore al riferimento. Lo script
    segnala come sospetto solo un ammanco oltre la soglia -TolerancePercent (default 3%).

.PARAMETER SourceDir
    Cartella con i PST da verificare. Default: lo staging export-locale\ del progetto.

.PARAMETER Expected
    Hashtable label -> item attesi per casella. Default vuoto: passare i conteggi reali, es.
    -Expected @{ CasellaA = 12345; CasellaB = 67890 }. Senza, lo script elenca i conteggi per file
    senza emettere un verdetto per casella.

.PARAMETER LabelMap
    Hashtable label -> regex sul nome file per assegnare un PST a una casella.
    Default vuoto: passare -LabelMap @{ CasellaA = 'CasellaA'; CasellaB = 'CasellaB' } per raggruppare
    i PST per casella in base a un frammento del nome file (case-insensitive).

.PARAMETER TolerancePercent
    Ammanco percentuale entro cui l'export e' considerato OK. Default 3.

.EXAMPLE
    .\Verify-PstCompleteness.ps1
    # Verifica i PST in export-locale\ contro i numeri di Fase 0 delle due caselle Intrawelt.

.EXAMPLE
    .\Verify-PstCompleteness.ps1 -Expected @{ Tizio = 12345 } -LabelMap @{ Tizio = 'tizio' }
    # Riuso su altra casella.
#>
[CmdletBinding()]
param(
    [string]$SourceDir,
    [hashtable]$Expected = @{},
    [hashtable]$LabelMap = @{},
    [double]$TolerancePercent = 3,
    [string]$NameLike = '*'
)

$ErrorActionPreference = 'Stop'

# --- Risoluzione percorsi e report ---
$projRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
if (-not $SourceDir) { $SourceDir = Join-Path $projRoot 'export-locale' }
$SourceDir = (Resolve-Path $SourceDir).Path
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$report = Join-Path (Join-Path $projRoot 'export-locale') ("completeness-check-$stamp.txt")
New-Item -ItemType Directory -Force -Path (Split-Path $report) | Out-Null
Start-Transcript -Path $report -Force | Out-Null

Write-Host "===== VERIFICA COMPLETEZZA EXPORT PST =====" -ForegroundColor Cyan
Write-Host ("Sorgente : {0}" -f $SourceDir)
Write-Host ("Tolleranza ammanco: {0}%" -f $TolerancePercent)

$pstFiles = @(Get-ChildItem -Path $SourceDir -Filter *.pst -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $NameLike })
if ($pstFiles.Count -eq 0) {
    Write-Warning "Nessun file .pst trovato in $SourceDir (NameLike '$NameLike'). Esegui prima l'export da Outlook."
    Stop-Transcript | Out-Null
    return
}
if ($NameLike -ne '*') { Write-Host ("Filtro file    : {0}" -f $NameLike) }

# --- Outlook COM ---
# Lo script conta aprendo i PST via automazione e richiede uno stato pulito. Se un'istanza di Outlook
# e' in esecuzione (inclusi i processi "fantasma" lasciati da un run precedente o un Outlook chiuso
# da pochi secondi e non ancora terminato), la creazione dell'oggetto COM fallisce con 0x80080005
# (CO_E_SERVER_EXEC_FAILURE). Si forza quindi la chiusura, si attende la fine effettiva del processo,
# poi si avvia un'istanza propria con un paio di tentativi; l'istanza viene chiusa in coda.
Get-Process outlook -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$waited = 0
while ((Get-Process outlook -ErrorAction SilentlyContinue) -and $waited -lt 15) { Start-Sleep -Seconds 1; $waited++ }
$outlook = $null
for ($try = 1; $try -le 3 -and -not $outlook; $try++) {
    try { $outlook = New-Object -ComObject Outlook.Application }
    catch { Start-Sleep -Seconds 3 }
}
if (-not $outlook) {
    Write-Warning "Impossibile avviare Outlook via COM (0x80080005). Chiudi Outlook manualmente e riprova."
    Stop-Transcript | Out-Null
    return
}
$ns = $outlook.GetNamespace('MAPI')

# Mappa dei PST gia' caricati in Outlook (per non riaprirli/rimuoverli)
$loaded = @{}
foreach ($s in $ns.Stores) {
    try { if ($s.FilePath) { $loaded[$s.FilePath.ToLower()] = $s } } catch {}
}

function Get-FolderItemCount {
    param($folder)
    $count = 0
    try { $count = [int]$folder.Items.Count } catch {}
    foreach ($sub in $folder.Folders) { $count += (Get-FolderItemCount -folder $sub) }
    return $count
}

# label -> totale contato ; e dettaglio per file
$totByLabel = @{}
foreach ($k in $Expected.Keys) { $totByLabel[$k] = 0 }
$perFile = @()

foreach ($pst in $pstFiles) {
    $path = $pst.FullName
    $added = $false
    $store = $null
    try {
        if ($loaded.ContainsKey($path.ToLower())) {
            $store = $loaded[$path.ToLower()]
        } else {
            $ns.AddStoreEx($path, 3) | Out-Null   # 3 = olStoreUnicode
            $added = $true
            foreach ($s in $ns.Stores) {
                try { if ($s.FilePath -and $s.FilePath.ToLower() -eq $path.ToLower()) { $store = $s } } catch {}
            }
        }
        if (-not $store) { throw "store non trovato dopo l'apertura" }
        $root = $store.GetRootFolder()
        $n = Get-FolderItemCount -folder $root

        # Assegna a una label in base al nome file
        $label = '(non classificato)'
        foreach ($k in $LabelMap.Keys) {
            if ($pst.Name -match $LabelMap[$k]) { $label = $k; break }
        }
        if ($totByLabel.ContainsKey($label)) { $totByLabel[$label] += $n }
        $perFile += [pscustomobject]@{ File = $pst.Name; Items = $n; Casella = $label }
        Write-Host ("  [{0,-10}] {1,10:N0} item  <- {2}" -f $label, $n, $pst.Name)
    }
    catch {
        Write-Warning ("Errore sul PST {0}: {1}" -f $pst.Name, $_.Exception.Message)
        $perFile += [pscustomobject]@{ File = $pst.Name; Items = $null; Casella = 'ERRORE' }
    }
    finally {
        if ($added -and $store) {
            try { $ns.RemoveStore($store.GetRootFolder()) } catch {}
        }
    }
}

# --- VERDETTO per casella ---
Write-Host "`n===== VERDETTO PER CASELLA =====" -ForegroundColor Yellow
$allOk = $true
foreach ($label in ($Expected.Keys | Sort-Object)) {
    $exp = [int]$Expected[$label]
    $got = [int]$totByLabel[$label]
    $delta = $got - $exp
    $pct = if ($exp -gt 0) { [math]::Round(($delta / $exp) * 100, 2) } else { 0 }
    $shortfall = if ($delta -lt 0) { [math]::Abs($pct) } else { 0 }
    Write-Host ("`n  Casella   : {0}" -f $label)
    Write-Host ("  Attesi    : {0,10:N0}  (Fase 0)" -f $exp)
    Write-Host ("  Contati   : {0,10:N0}  (somma PST)" -f $got)
    Write-Host ("  Delta     : {0,10:N0}  ({1:+0.##;-0.##;0}%)" -f $delta, $pct)
    if ($got -eq 0) {
        Write-Host "  ESITO     : NESSUN PST per questa casella -> export mancante" -ForegroundColor Red
        $allOk = $false
    }
    elseif ($shortfall -le $TolerancePercent) {
        Write-Host ("  ESITO     : OK (ammanco {0}% entro tolleranza {1}%)" -f $shortfall, $TolerancePercent) -ForegroundColor Green
    }
    else {
        Write-Host ("  ESITO     : SOSPETTO INCOMPLETO (ammanco {0}% oltre tolleranza {1}%)" -f $shortfall, $TolerancePercent) -ForegroundColor Red
        Write-Host "              Probabile archivio online scaricato a meta'. Rifare i blocchi mancanti." -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host "`n===== RIEPILOGO =====" -ForegroundColor Cyan
if ($allOk) { Write-Host "Tutte le caselle entro tolleranza. Si puo' procedere con la Fase 4 (Archive-PstExport.ps1)." -ForegroundColor Green }
else        { Write-Host "Almeno una casella e' sotto soglia o mancante: NON archiviare finche' non e' completa." -ForegroundColor Red }
Write-Host ("`nReport salvato in: {0}" -f $report) -ForegroundColor Cyan

Stop-Transcript | Out-Null
# L'istanza l'ha avviata lo script (ha forzato uno stato pulito a inizio): va sempre chiusa.
try { $outlook.Quit() } catch {}
try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ns) | Out-Null } catch {}
try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null } catch {}
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
# Rete di sicurezza: se l'istanza COM non e' terminata, la si forza, cosi' il prossimo avvio di
# Outlook (manuale, per l'export successivo) non trova un processo che lo blocca.
Start-Sleep -Seconds 2
Get-Process outlook -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
