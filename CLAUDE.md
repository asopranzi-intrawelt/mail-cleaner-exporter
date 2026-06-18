# mail-cleaner-exporter

> Istruzioni di team, versionate. Questo file è l'indice del progetto: indicizza i soli file
> satellite tracciati e descrive la procedura di ripresa. Le preferenze personali vivono in
> `CLAUDE.local.md`, ignorato da git, non qui.

## Cos'è questo progetto

Toolkit operativo riusabile per **esportare in modo statico le caselle di Exchange Online**
(Microsoft 365, tenant Intrawelt) verso una risorsa di rete, allo scopo di archiviare la posta
prima di liberarne lo spazio. Il metodo di riferimento è **Microsoft Purview eDiscovery → export
PST** (lato server), corredato da script PowerShell per la verifica preliminare in sola lettura e
per l'archiviazione con checksum. Caso d'uso che ha originato il progetto: le caselle condivise
`mmartinelli@intrawelt.com` e `roripa@intrawelt.com`, piene al 100% (primaria + archivio online).

## Procedura di ripresa in una sessione nuova

Lo stato del progetto è interamente recuperabile su disco. All'inizio di una sessione si segue
questo percorso fisso. Si legge per primo `.claude/memory/index.md`, che dà branch, commit di
riferimento, stato di verifica di ogni scheda e punto di ripresa. Si legge poi
`.claude/context/current-work.md` se c'è una feature attiva, per sapere cosa è in lavorazione e
quali sono i TODO e i limiti d'ambiente. Si invoca la skill `sync-context` per verificare il
drift tra schede e codice, e si leggono solo le schede pertinenti al task, mai tutte insieme. Il
work-log `.claude/memory/progress.md` e il registro `.claude/memory/decisions.md` forniscono la
storia e le decisioni quando servono. Il materiale grezzo sotto `_notes/` si apre solo per
verificare un requisito originale.

## Indice dei file satellite tracciati

Memoria e meta-stato, sotto `.claude/memory/`, letti sempre a inizio sessione.

```
.claude/memory/index.md       snapshot e tabella di sincronizzazione, da leggere per primo
.claude/memory/progress.md    work-log append-only di passi e riconciliazioni
.claude/memory/decisions.md   registro ADR-lite delle decisioni architetturali
```

Schede tecniche, sotto `.claude/context/`, con frontmatter di riconciliazione.

```
.claude/context/STACK.md                stack, flussi del tooling, ruolo degli script
.claude/context/design-and-security.md  paradigmi e sicurezza (read-only, niente segreti)
.claude/context/deployment.md           dove gira e con quali prerequisiti
.claude/context/dev-testing.md          come si prova il tooling
.claude/context/current-work.md         export attivo (caselle Ripa/Martinelli)
.claude/context/roadmap.md              direzione e priorità
.claude/context/compliance-gdpr.md      conformità GDPR/privacy + registro azioni Purview
```

Procedura operativa riusabile, come skill:

```
.claude/skills/export-shared-mailbox/SKILL.md   runbook completo Fasi 0-4 + script
```

Regole modulari caricate su necessità, sotto `.claude/rules/`, e skill del motore, sotto
`.claude/skills/`. Lo standard di sistema completo è in `.claude/PROJECT-SYSTEM.md`.

## Vincoli di team

Le operazioni di `git add`, commit e push restano sempre manuali dell'utente: l'agente prepara i
file, non committa. L'anatomia è pronta per `git init`, con identità locale secondo
`.claude/rules/git-identity-and-repo.md` (profilo di lavoro `github-corp`,
asopranzi@intrawelt.com). Repository di destinazione su GitHub:
`https://github.com/asopranzi-intrawelt/mail-cleaner-exporter`, da agganciare come remote
`git@github-corp:asopranzi-intrawelt/mail-cleaner-exporter.git`. Lo stile di documentazione e di
interazione è quello di
`.claude/rules/interaction-style.md`. Claude non scrive autonomamente nei file di memoria e di
contesto: li aggiorna solo su richiesta esplicita, così il versionamento resta sotto controllo
umano.

**Vincolo di dominio non negoziabile:** gli script di questo progetto sono di sola lettura ed
export. Nessuna operazione di cancellazione o svuotamento delle caselle va eseguita senza una
richiesta esplicita e separata dell'utente, ad archivio già verificato.
