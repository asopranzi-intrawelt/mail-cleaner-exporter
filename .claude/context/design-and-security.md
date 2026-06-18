---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
---

# Design e sicurezza applicativa

> Popolare leggendo il codice attuale. I diagrammi referenziati vivono in `diagrams/` in
> corrispondenza uno a uno con i componenti descritti (sezione 7).

## Paradigmi di software design

Script idempotenti e parametrici, separati per responsabilità: uno per la verifica (lettura),
uno per l'archiviazione (copia + integrità). Nessuno stato condiviso tra le invocazioni: ogni
script apre la propria connessione, fa il suo lavoro e si disconnette. I valori specifici
dell'ambiente (caselle, destinazione di rete) sono parametri con default ragionevoli, mai cablati
nel corpo dello script, così il toolkit è riusabile per export futuri e portabile su macchine
diverse (vedi ADR-004).

## Sicurezza applicativa

- **Principio di sola lettura per default**: `Verify-MailboxState.ps1` esegue solo cmdlet di
  lettura (`Get-EXOMailbox`, `Get-EXOMailboxStatistics`, `Get-RetentionCompliancePolicy`).
  Nessuno script del progetto cancella o svuota caselle: lo svuotamento è una fase futura,
  separata e da autorizzare esplicitamente (vincolo ribadito in `CLAUDE.md`).
- **Autenticazione**: interattiva di default (login Microsoft in una finestra PowerShell reale; il
  broker WAM richiede una finestra), nessuna credenziale salvata su disco. Per l'esecuzione non
  presidiata, app-only con certificato (`-AppId` / `-CertificateThumbprint` / `-Organization`). Si
  autentica con un account dotato dei ruoli necessari (Compliance/eDiscovery Manager per l'export).
  Vedi ADR-005 (supera ADR-003).
- **Gestione dei segreti**: nessun segreto nel repository. Token e sessioni restano in memoria
  per la durata dell'esecuzione. I `.gitignore` escludono report locali (transcript) e i PST.
- **Dato sensibile**: i PST contengono posta aziendale; restano nello staging locale ignorato da
  git (`export-locale/`) e sulla destinazione di rete, mai dentro il repository.

## Diagrammi

| Diagramma | Sorgente | Componenti rappresentati |
|---|---|---|
| (nessuno per ora) | | |
