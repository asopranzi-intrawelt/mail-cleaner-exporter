<#
.SYNOPSIS
    Fase 4 del runbook export-shared-mailbox: copia i PST esportati dallo staging locale alla
    risorsa di rete (parametrica) e verifica l'integrità con checksum SHA256.

.DESCRIPTION
    Calcola lo SHA256 di ogni .pst nello staging, li copia nella destinazione di rete sotto una
    sotto-cartella etichettata, ricalcola lo SHA256 a destinazione e confronta. Scrive
    checksums.csv accanto ai file copiati e segnala eventuali mismatch. Non cancella mai la
    sorgente: la pulizia dello staging resta una scelta manuale.

    La destinazione è parametrica (ADR-004): accetta sia un'unità mappata (es. V:\) sia un
    percorso UNC (\\server\share), così lo script è portabile tra workstation e VM in LAN.

.PARAMETER SourceDir
    Cartella di staging locale con i PST scaricati dall'eDiscovery Export Tool.

.PARAMETER ArchiveRoot
    Radice della destinazione di rete. Default: V:\Archivio-Email. Accetta percorsi UNC.

.PARAMETER Label
    Sotto-cartella di destinazione (es. Ripa-2026). I file finiscono in <ArchiveRoot>\<Label>.

.PARAMETER WhatIfCopy
    Mostra cosa verrebbe copiato senza eseguire la copia.

.EXAMPLE
    .\Archive-PstExport.ps1 -SourceDir ..\..\..\..\export-locale -ArchiveRoot V:\Archivio-Email -Label Ripa-2026

.EXAMPLE
    .\Archive-PstExport.ps1 -SourceDir D:\staging -ArchiveRoot \\nas\archivio -Label Ripa-2026
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourceDir,
    [string]$ArchiveRoot = 'V:\Archivio-Email',
    [Parameter(Mandatory)][string]$Label,
    [switch]$WhatIfCopy
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceDir)) { throw "SourceDir non trovata: $SourceDir" }

$psts = Get-ChildItem -LiteralPath $SourceDir -Recurse -Filter *.pst -File
if (-not $psts) { throw "Nessun file .pst trovato in $SourceDir" }

$dest = Join-Path $ArchiveRoot $Label
Write-Host "== Archiviazione di $($psts.Count) PST ==" -ForegroundColor Cyan
Write-Host "Sorgente:     $SourceDir"
Write-Host "Destinazione: $dest`n"

if (-not (Test-Path -LiteralPath $ArchiveRoot)) {
    throw "ArchiveRoot non raggiungibile: $ArchiveRoot (unità di rete non montata o UNC non accessibile?)"
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$rows = foreach ($f in $psts) {
    Write-Host "-> $($f.Name) ($([math]::Round($f.Length/1GB,2)) GB)"
    $srcHash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $target  = Join-Path $dest $f.Name

    if ($WhatIfCopy) {
        Write-Host "   [WhatIf] copierei in $target" -ForegroundColor Yellow
        [pscustomobject]@{ File=$f.Name; SourceSHA256=$srcHash; DestSHA256='(whatif)'; Match='(whatif)'; SizeGB=[math]::Round($f.Length/1GB,2) }
        continue
    }

    Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    $dstHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    $match   = $srcHash -eq $dstHash
    if ($match) { Write-Host "   OK integrità verificata" -ForegroundColor Green }
    else        { Write-Warning "   MISMATCH SHA256 su $($f.Name): la copia NON è integra" }

    [pscustomobject]@{ File=$f.Name; SourceSHA256=$srcHash; DestSHA256=$dstHash; Match=$match; SizeGB=[math]::Round($f.Length/1GB,2) }
}

if (-not $WhatIfCopy) {
    $csv = Join-Path $dest 'checksums.csv'
    $rows | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    Write-Host "`nChecksum salvati in: $csv" -ForegroundColor Cyan
    $bad = @($rows | Where-Object { -not $_.Match })
    if ($bad.Count -gt 0) {
        Write-Warning "$($bad.Count) file con mismatch: ricopiare prima di considerare l'archivio valido."
    } else {
        Write-Host "Tutti i PST copiati e verificati ($($rows.Count) file)." -ForegroundColor Green
    }
}
