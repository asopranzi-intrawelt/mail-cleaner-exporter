---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
---

# Stack applicativo

> Documento di recupero più importante: tracciato, perché un collega che clona deve vederlo.

## Stack e runtime

Toolkit di automazione amministrativa, non un'applicazione. Componenti:

- **PowerShell** (Windows PowerShell 5.1 / PowerShell 7) come linguaggio degli script.
- **Modulo `ExchangeOnlineManagement`** (rilevata v3.9.2 sulla macchina attuale) per connettersi
  a Exchange Online e leggere stato e statistiche delle caselle. Connessione interattiva (in una
  finestra PowerShell reale) oppure app-only con certificato per l'esecuzione headless; il
  device-code NON esiste in EXO 3.x. Vedi `design-and-security.md` e ADR-005 (supera ADR-003).
- **Microsoft Purview portal** (purview.microsoft.com), area **eDiscovery**, per l'export PST
  vero e proprio: passo manuale via browser, non scriptabile interamente (vedi runbook).
- **eDiscovery Export Tool** (app ClickOnce) per scaricare i pacchetti PST.

Nessuna dipendenza da pacchetti di terze parti; nessun runtime applicativo da deployare.

## Alternative deliberatamente escluse

- `New-MailboxExportRequest`: solo Exchange on-premises, non disponibile in Exchange Online.
- `New-ComplianceSearchAction -Export` da PowerShell: il ramo `-Export` è funzionale solo
  on-prem; in Exchange Online il download passa comunque dal portale.
- Export via Outlook desktop: inaffidabile su caselle piene e su archivio online (limite PST
  50 GB di default, archivio spesso non scaricato per intero).

Motivazioni dettagliate in `.claude/memory/decisions.md` (ADR-002).

## Flussi di codice e ruolo architetturale dei file

```
.claude/skills/export-shared-mailbox/SKILL.md            runbook completo Fasi 0-4 (procedura)
.claude/skills/export-shared-mailbox/scripts/
    Verify-MailboxState.ps1   Fase 0: verifica read-only (dimensioni primaria+archivio,
                              stato hold/retention/quote) per N caselle parametriche
    Archive-PstExport.ps1     Fase 4: copia i PST dallo staging locale alla destinazione di
                              rete parametrica e calcola/registra i checksum SHA256
```

Le Fasi 1-3 (caso eDiscovery, ricerca, export e download) sono manuali nel portale Purview e
sono descritte nel `SKILL.md`; gli script coprono le fasi automatizzabili agli estremi (verifica
prima, integrità dopo).

## Riferimenti a snippet

- `Verify-MailboxState.ps1` — parametro `-Mailboxes` (default `mmartinelli@intrawelt.com`,
  `roripa@intrawelt.com`); auth interattiva di default, oppure app-only con
  `-AppId` / `-CertificateThumbprint` / `-Organization`.
- `Archive-PstExport.ps1` — parametri `-SourceDir` (staging locale) e `-ArchiveRoot` (default
  `V:\Archivio-Email`, accetta percorsi UNC), parametro `-Label` per la sotto-cartella.
