---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
stato: completato (export verificato e archiviato 2026-06-22)
---

# Lavoro in corso

> La fonte di verità su cosa è fatto resta `memory/index.md` e il work-log, non le spunte di
> questo file.

## Feature: Export statico caselle Casella A & Casella B

Cosa fa: archiviare integralmente (primaria + archivio online) le caselle condivise
`casella-a@intrawelt.com` e `casella-b@intrawelt.com` in PST sulla destinazione di rete, come
backup statico. A essere pieno al 100% è l'archivio online (50/50 GB); le primarie hanno spazio.
Nessuna cancellazione in questa fase.

Numeri di riferimento (Fase 0, 2026-06-12) — completezza attesa dell'export PST:

```
Casella A  (casella-a@): primaria 16,28 GB / 46.003 item  + archivio 50 GB / 85.867 item
                                  => totale ~66 GB, ~131.870 item
Casella B     (casella-b@):      primaria 14,84 GB / 42.910 item  + archivio 50 GB / 97.424 item
                                  => totale ~65 GB, ~140.334 item
Hold: NESSUNO su entrambe (LitigationHold False, InPlaceHolds {}, RetentionHold False).
      => in futuro la cancellazione libererà spazio. AutoExpandingArchive: False.
```

File da creare:

```
(nessuno: il tooling è pronto; questa feature è un'esecuzione del runbook)
```

File da modificare:

```
.claude/memory/progress.md   annotare l'esito di ogni fase (dimensioni pre-export, percorso archivio)
```

Definition of done:

- [x] Fase 0 eseguita: dimensioni e stato hold delle due caselle registrati (2026-06-12)
- [x] Metodo deciso: Outlook classico (operatore senza E3/E5, eDiscovery non praticabile; ADR-007)
- [x] Export PST completato per entrambe le caselle (archivio a blocchi; cartelle grandi a tranche per data)
- [x] Completezza verificata per CONTEGGIO ITEM contro la baseline esportabile (cartella per cartella; ADR-008)
- [x] PST copiati sul NAS con checksum SHA256 verificati (7 file Casella A, 11 Casella B; checksums.csv OK)
- [ ] (Facoltativo) apertura a campione di un PST per casella in Outlook a riprova visiva

Domande aperte:

- Stato hold/retention: VERIFICATO in Fase 0 — nessun hold sulle due caselle. Restano tre
  retention policy a livello tenant (due attive) non applicate a queste caselle; da riconfermare
  comunque prima dell'eventuale svuotamento futuro.
- Destinazione di archivio (USATA): `\\NAS-INTRA3\Public\Archivio-Email\CasellaA-2026` e
  `...\CasellaB-2026`. Si è usato il percorso UNC e non la lettera `V:` perché la finestra
  PowerShell elevata non vedeva l'unità mappata dall'utente normale (vedi troubleshooting in
  SKILL.md). Lo staging `export-locale\` è da svuotare ora che la copia è verificata.

Esito finale (2026-06-22): export completo e integro. Casella A 127.740 item nei PST (archivio
82.400 = baseline esportabile, esatto; primaria 45.340). Casella B ~132.717 (Posta inviata 51.184
esatti in 3 tranche per data; Posta in arrivo 40.404 in 2 tranche, meno 15 messaggi con data
anomala; cartelle piccole tutte esatte; primaria 40.706). Lo scarto rispetto ai totali grezzi di
Fase 0 è interamente non-posta (dumpster, cartelle di sistema, metodo di conteggio). Dettaglio nel
work-log e nelle evidenze in `_notes/audit-export-2026/`.

## Riconciliazione

Ultima verifica: 2026-06-22, export completato e archiviato (commit PENDING-FIRST-COMMIT).
