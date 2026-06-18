# Snapshot di sincronizzazione

> Da leggere per primo a inizio sessione. Fotografa lo stato del progetto al commit di
> riferimento e mappa ogni scheda al suo stato di verifica. È la fonte di verità su cosa è fatto,
> non le spunte del diario.

## Stato

```
Branch attivo:         main (pianificato; repo git non ancora inizializzato)
Commit di riferimento: PENDING-FIRST-COMMIT
Data snapshot:         2026-06-12
```

## Stato di verifica delle schede

| Scheda | last-verified | Stato |
|---|---|---|
| STACK.md | PENDING-FIRST-COMMIT | aggiornata |
| design-and-security.md | PENDING-FIRST-COMMIT | aggiornata |
| deployment.md | PENDING-FIRST-COMMIT | aggiornata |
| dev-testing.md | PENDING-FIRST-COMMIT | aggiornata |
| current-work.md | PENDING-FIRST-COMMIT | aggiornata |
| roadmap.md | PENDING-FIRST-COMMIT | aggiornata |
| compliance-gdpr.md | PENDING-FIRST-COMMIT | aggiornata |

## Punto di ripresa

Fase 0 OK (caselle misurate, nessun hold) e Fase 1 OK. CAMBIO METODO il 2026-06-15 (ADR-007): la via
eDiscovery è ABBANDONATA per questo export. Motivo: l'operatore `asopranzi@` ha solo Business
Standard (niente E3/E5) e la nuova eDiscovery unificata (post ritiro 31/08/2025) richiede E3/E5 per
chiunque lavori ai casi, più billing a consumo. L'utente ha scelto di non comprare licenze.

Metodo attuale = **export da Outlook classico (Win32)**. Sequenza manuale dell'utente, ancora DA
FARE: (1) Full Access operatore sulle due caselle condivise via `Add-MailboxPermission` (auto-map);
(2) in Outlook classico esportare per ciascuna casella la primaria in un PST e l'archivio online a
BLOCCHI su più PST (l'archivio non va in cache, e il PST Unicode ha tetto 50 GB: alzare
`MaxLargeFileSize`/`WarnLargeFileSize` via registro), verso `D:\mail-cleaner-exporter\export-locale\`;
(3) verifica completezza con `scripts/Verify-PstCompleteness.ps1` (confronta item PST vs Fase 0,
tolleranza 3%); (4) **Fase 4** `Archive-PstExport.ps1` → `V:\Archivio-Email\<Casella>-2026`.
Completezza attesa: ~131.870 item (Martinelli), ~140.334 (Ripa). Trappole: usare Outlook classico
NON il "nuovo Outlook"; archivio a blocchi; tetto PST. Se l'archivio risulta incompleto oltre
tolleranza e non recuperabile, rivalutare una E3 temporanea per tornare a eDiscovery.

DA FARE nella sintesi finale: allineare SKILL.md (variante Outlook) e la DoD di current-work.md,
ancora scritte sul metodo eDiscovery. Vedi ADR-002 (superata per questo export), ADR-006, ADR-007.
