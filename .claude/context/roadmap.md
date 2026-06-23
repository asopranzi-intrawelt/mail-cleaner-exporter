---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths: []
last-verified-commit: PENDING-FIRST-COMMIT
---

# Roadmap

> Direzione e priorità del progetto. Tracciata. Non è il work-log: qui sta dove si va, non cosa è
> già stato fatto.

## Direzione

Disporre di un toolkit riusabile e portabile per esportare in modo statico qualsiasi casella di
Exchange Online del tenant Intrawelt, eseguibile sia da workstation sia, in prospettiva, da una
VM centralizzata, con verifica di integrità dell'archivio.

## Priorità

1. Completare l'export delle caselle `casella-a@` e `casella-b@` (vedi `current-work.md`): è il
   caso che ha originato il progetto e libera spazio su caselle al 100%.
2. Definire la procedura, separata e da autorizzare, di **svuotamento** delle caselle dopo la
   verifica dell'archivio, tenendo conto degli hold/retention (con hold attivo la cancellazione
   non libera spazio finché l'hold non è gestito).
3. Valutare il deploy in VM su Proxmox in LAN, con destinazione di rete via percorso UNC.

## Idee e ipotesi da verificare

- Mitigazione non distruttiva per le caselle al 100%: abilitare l'auto-expanding archive per dare
  spazio subito senza cancellare nulla (da verificare l'opportunità caso per caso).
- Eventuale schedulazione periodica degli export ricorrenti, se il deploy in VM lo giustifica.
