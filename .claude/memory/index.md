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

STATO 2026-06-22: EXPORT COMPLETATO, VERIFICATO E ARCHIVIATO. Entrambe le caselle esportate da
Outlook classico, completezza verificata per conteggio item contro la baseline esportabile, e PST
copiati con SHA256 OK su `\\NAS-INTRA3\Public\Archivio-Email\CasellaA-2026` e `...\CasellaB-2026`
(7 + 11 file). Totali PST: Casella A 127.740, Casella B ~132.717. Evidenze in
`_notes/audit-export-2026/`. Resta fuori, da autorizzare a parte, il solo svuotamento futuro delle
caselle. Quanto segue e' lo storico del percorso che ha portato qui.

### Avvio di un nuovo export (altre caselle) - per la prossima sessione

Il toolkit e' una skill riusabile e parametrica: per archiviare altre caselle non si reinventa
nulla. Si parte dal runbook `.claude/skills/export-shared-mailbox/SKILL.md`, che copre le Fasi 0-4 e
ha in coda la sezione troubleshooting con tutti i problemi gia' incontrati e risolti. In concreto:
si esegue la Fase 0 (`Verify-MailboxState.ps1` piu' i CSV `Get-MailboxFolderStatistics`) sui nuovi
indirizzi per ottenere i conteggi e la baseline esportabile; si sceglie il metodo in base alla
licenza dell'operatore (Outlook classico senza E3/E5, eDiscovery se licenziato; ADR-007); si
esporta a blocchi, spezzando per data le cartelle grandi e piatte; si verifica per CONTEGGIO ITEM
contro la baseline (`Verify-PstCompleteness.ps1`, ADR-008); si archivia con SHA256
(`Archive-PstExport.ps1`, percorso UNC se l'unita' mappata non e' visibile). L'eventuale svuotamento
e' nella guida separata `.claude/skills/export-shared-mailbox/SVUOTAMENTO-CASELLE.md`, da autorizzare
a parte. Gli pseudonimi e la relativa mappa restano una convenzione per casella: la corrispondenza
con le identita' reali va tenuta solo in `_notes/` (non committato).

### Storico del percorso

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
Completezza attesa: ~131.870 item (Casella A), ~140.334 (Casella B). Trappole: usare Outlook classico
NON il "nuovo Outlook"; archivio a blocchi; tetto PST. Se l'archivio risulta incompleto oltre
tolleranza e non recuperabile, rivalutare una E3 temporanea per tornare a eDiscovery.

DA FARE nella sintesi finale: allineare SKILL.md (variante Outlook) e la DoD di current-work.md,
ancora scritte sul metodo eDiscovery. Vedi ADR-002 (superata per questo export), ADR-006, ADR-007.
