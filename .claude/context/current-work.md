---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
stato: in corso
---

# Lavoro in corso

> La fonte di verità su cosa è fatto resta `memory/index.md` e il work-log, non le spunte di
> questo file.

## Feature: Export statico caselle Martinelli & Ripa

Cosa fa: archiviare integralmente (primaria + archivio online) le caselle condivise
`mmartinelli@intrawelt.com` e `roripa@intrawelt.com` in PST sulla destinazione di rete, come
backup statico. A essere pieno al 100% è l'archivio online (50/50 GB); le primarie hanno spazio.
Nessuna cancellazione in questa fase.

Numeri di riferimento (Fase 0, 2026-06-12) — completezza attesa dell'export PST:

```
Mery Martinelli  (mmartinelli@): primaria 16,28 GB / 46.003 item  + archivio 50 GB / 85.867 item
                                  => totale ~66 GB, ~131.870 item
Roberta Ripa     (roripa@):      primaria 14,84 GB / 42.910 item  + archivio 50 GB / 97.424 item
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
- [ ] Ruolo Export verificato/assegnato in Purview
- [ ] Export PST completato e scaricato per entrambe le caselle
- [ ] PST copiati sulla destinazione di rete con checksum SHA256 verificati
- [ ] Archivio aperto a campione in Outlook e confrontato con i conteggi della Fase 0

Domande aperte:

- Stato hold/retention: VERIFICATO in Fase 0 — nessun hold sulle due caselle. Restano tre
  retention policy a livello tenant (due attive) non applicate a queste caselle; da riconfermare
  comunque prima dell'eventuale svuotamento futuro.
- Destinazione di archivio (DEFINITA): `V:\Archivio-Email\<Casella>-2026`, una sottocartella per
  casella → `V:\Archivio-Email\Martinelli-2026` e `V:\Archivio-Email\Ripa-2026`. V: = NAS mappato
  (~1,66 TB liberi). Rivalutare il percorso (UNC) se si passa a esecuzione da VM Proxmox.

## Riconciliazione

Ultima verifica: 2026-06-11 al commit PENDING-FIRST-COMMIT.
