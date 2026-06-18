---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
---

# Test di sviluppo

> Popolare leggendo la configurazione reale dei test. La checklist operativa locale dei test
> manuali vive invece in `_notes/TEST-CHECKLIST.md`, ignorata da git.

## Test runner e comandi

Nessun framework di test automatico: il toolkit è composto da script PowerShell amministrativi il
cui esito si verifica eseguendoli contro il tenant reale. Controlli di base prima dell'uso:

```powershell
# Sintassi degli script senza eseguirli (parsing)
powershell -NoProfile -Command "[void][System.Management.Automation.Language.Parser]::ParseFile('.\.claude\skills\export-shared-mailbox\scripts\Verify-MailboxState.ps1',[ref]$null,[ref]$null)"
```

## Rotte e dati mockati

Nessun mock: gli script parlano direttamente con Exchange Online e con il filesystem di rete.
`Verify-MailboxState.ps1` è sicuro da eseguire in qualunque momento perché è di sola lettura, e
funge da test di connettività e di permessi.

## Hook e controlli di qualità

Verifica manuale: la Fase 0 deve restituire dimensioni e conteggi coerenti con quanto mostrato
nel portale; `Archive-PstExport.ps1` deve produrre un `checksums.csv` con hash che combaciano
prima e dopo la copia in rete. Checklist operativa di dettaglio in `_notes/TEST-CHECKLIST.md`.
