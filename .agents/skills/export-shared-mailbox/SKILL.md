---
name: export-shared-mailbox
description: >
  Runbook riusabile per esportare in modo statico una o piu' caselle di Exchange Online
  (Microsoft 365) in file PST verso una risorsa di rete, come backup prima di liberarne lo
  spazio. Copre la verifica preliminare in sola lettura (dimensioni, hold, statistiche per
  cartella), l'export, la verifica di completezza per CONTEGGIO ITEM e l'archiviazione con
  checksum SHA256. Il metodo operativo predefinito e' l'export da Outlook classico, scelto
  quando l'operatore non ha licenza E3/E5 (necessaria alla nuova eDiscovery); se l'operatore
  e' licenziato, eDiscovery resta l'alternativa server-side. NON cancella ne' svuota le
  caselle: lo svuotamento e' una fase separata, da autorizzare esplicitamente ad archivio
  verificato. Parametrico su caselle e destinazione di rete.
---

<!-- generato da sync-codex-skills.py; non modificare -->

Leggere integralmente [`../../../.claude/skills/export-shared-mailbox/SKILL.md`](../../../.claude/skills/export-shared-mailbox/SKILL.md) e seguirne la procedura canonica. Risolvere i percorsi relativi dalla directory della skill canonica. Tradurre la sintassi o i nomi degli strumenti specifici di Claude negli equivalenti disponibili in Codex senza indebolire controlli, gate o limiti di autorizzazione.
