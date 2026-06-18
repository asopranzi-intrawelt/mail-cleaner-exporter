# Work-log

## 2026-06-18 - Identita git, remoto e allineamento standard

Impostata identita locale asopranzi/asopranzi@intrawelt + github-corp + OpenSSH; remoto origin asopranzi-intrawelt/mail-cleaner-exporter (commit/push manuali; repo senza commit pregressi). Update additivo standard: rules token-economy/manual-screenshots, engine skills + onboard, bundle/PACKAGES. Preservati skill custom export-shared-mailbox, schede context (compliance-gdpr ecc.), interaction-style. Niente pacchetti esterni (tool PowerShell). .gitignore: gia escludeva *.pst/*.zip/export-locale; aggiunti *.tmp e .claude/screenshot_*.png.

---


> Append-only, in ordine cronologico inverso (la voce piÃ¹ recente in alto). Ogni passo
> significativo di codice e ogni intervento manuale rilevante lascia una voce con data, file
> toccati, motivo e commit di riferimento. Qui confluisce anche il log di riconciliazione dei
> documenti `.docx`, con il nome del documento sorgente e l'esito, cosÃ¬ la data di allineamento
> sopravvive a un clone.

## 2026-06-15 â€” Cambio metodo: da eDiscovery a Outlook desktop (vincolo licenza E3/E5)

Commit: PENDING-FIRST-COMMIT
File toccati: `scripts/Verify-PstCompleteness.ps1` (nuovo), `memory/decisions.md` (ADR-007),
`memory/index.md` (punto di ripresa), `.gitignore` (ignora `Check-License.ps1`).
Scoperta bloccante: verificata la licenza dell'operatore `asopranzi@` (Check-License.ps1, sola
lettura Graph) -> solo Microsoft 365 Business Standard (SKU O365_BUSINESS_PREMIUM) + Defender Plan 2
(ATP_ENTERPRISE), NESSUNA E3/E5. Ricerca su Microsoft Learn: dal 31/08/2025 Content Search ed
eDiscovery Standard classici sono ritirati e fusi nell'unica nuova esperienza eDiscovery, che
richiede E3/E5 Enterprise per chi lavora ai casi (anche admin) + billing a consumo sullo storage.
Quindi il workaround Standard di ADR-006 non basta piu'. L'utente ha scelto di NON acquistare
licenze e di ripiegare sull'export da Outlook classico (vedi ADR-007).
Fatto in questa sessione: creato lo script di verifica completezza che confronta gli item dei PST in
export-locale\ con i conteggi di Fase 0 (Martinelli 131.870, Ripa 140.334) con tolleranza 3%;
registrato ADR-007; aggiornato il punto di ripresa.
PROSSIMO (manuale utente): Full Access operatore sulle caselle, export Outlook a blocchi (primaria +
archivio), poi `Verify-PstCompleteness.ps1`, poi Fase 4 `Archive-PstExport.ps1` su V:.
DA FARE nella sintesi finale: aggiornare SKILL.md (variante Outlook nelle Fasi 2-3) e la DoD in
current-work.md, oggi ancora scritte sul metodo eDiscovery.

## 2026-06-15 â€” Ritiro strumenti eDiscovery classici + blocco Premium su "Origini dati caso"

Commit: PENDING-FIRST-COMMIT
File toccati: SKILL.md (Fasi 2-3), memory/index.md, memory/decisions.md (ADR-006).
Scoperte (verificate su Microsoft Learn / portale):
- eDiscovery Export Tool ClickOnce RITIRATO il 31/08/2025: il download dei pacchetti ora avviene
  direttamente dal portale (Process manager -> Export packages -> Download packages), con Edge e
  pop-up consentiti; pacchetti validi 14 giorni.
- `New-ComplianceSearchAction -Export` RITIRATO il 26/05/2025 (niente export via PowerShell).
  Resta valido `-Purge` per il FUTURO svuotamento.
- Nella nuova eDiscovery unificata la scheda "Origini dati del caso" (custodi/origini) e' una
  funzionalita' eDiscovery PREMIUM: tenant senza Premium -> blocco incontrato in Fase 2.
Via Standard da seguire: aggiungere le caselle come location a livello di RICERCA (non dalla scheda
"Origini dati del caso"), oppure usare il nuovo "Content search" (Soluzioni -> Content search).
Export con "Create PSTs" + "Organize data into separate PSTs" (un PST per casella; primaria+archivio
uniti in un unico PST), dimensione max PST configurabile (10 GB), scaricare in
`D:\mail-cleaner-exporter\export-locale\`. L'export richiede licenza E3/E5 sull'operatore
(asopranzi). Vedi ADR-006. PROSSIMO: completare Fase 2-3 (probabilmente sotto account2).

## 2026-06-12 â€” Operatore eDiscovery: confermato asopranzi@ (it@ non autenticabile)

Commit: PENDING-FIRST-COMMIT
File toccati: `scripts/Verify-MailboxState.ps1` (default UPN ripristinato), `context/compliance-gdpr.md`.
Motivo: si era valutato `it@intrawelt.com` come operatore funzionale, ma il sign-in non riesce
(probabile shared mailbox / accesso disabilitato). Si conferma `asopranzi@intrawelt.com`
(Global/Compliance Admin) come operatore eDiscovery; default `-UserPrincipalName` riportato ad
asopranzi@. Esito registrato nel documento di conformitÃ  (registro azioni). Creato anche lo
strumento riusabile `scripts/Check-OperatorAccount.ps1` per verificare l'idoneitÃ  di un account
operatore (tipo casella, sign-in, licenze, ruolo eDiscovery).

## 2026-06-12 â€” Documento di conformitÃ  GDPR creato

Commit: PENDING-FIRST-COMMIT
File toccati: `context/compliance-gdpr.md` (nuovo), `CLAUDE.md`, `memory/index.md`.
Motivo: messa per iscritto del quadro privacy/GDPR del trattamento. Registrato che i due soggetti
(`mmartinelli@`, `roripa@`) sono **ex dipendenti**, che l'ok a procedere Ã¨ stato acquisito in via
informale (Intrawelt NON ha un DPO formalmente nominato â†’ nessun parere RPD scritto; lasciati campi
"autorizzato da" da compilare). Evidenziati i punti 1 (soggetti/natura caselle) e 5 (informativa/
policy, DA CONFERMARE). Inclusi tutti i rilievi GDPR (art. 4 Stat. Lav., linee guida Garante, base
giuridica vs consenso, conservazione, minimizzazione) e un registro append-only delle azioni
Purview. Resta vincolo: solo export, nessuna cancellazione senza autorizzazione separata.

## 2026-06-12 â€” Fase 0 eseguita: misurate le due caselle (nessun hold)

Commit: PENDING-FIRST-COMMIT
File toccati: `context/current-work.md` (numeri di riferimento + DoD).
Esito Fase 0 (read-only) via `Verify-MailboxState.ps1` in finestra PowerShell reale:
- mmartinelli@intrawelt.com: primaria 16,28 GB / 46.003 item; archivio 50 GB / 85.867 item (pieno).
- roripa@intrawelt.com: primaria 14,84 GB / 42.910 item; archivio 50 GB / 97.424 item (pieno).
- Pieno = solo l'archivio online (50/50 GB); le primarie hanno spazio (quota 50 GB).
- Hold: NESSUNO su entrambe (LitigationHold False, InPlaceHolds {}, RetentionHold False,
  AutoExpandingArchive False). Tre retention policy tenant (due attive) NON applicate a queste
  caselle. => in futuro la cancellazione libererÃ  spazio.
Report: `export-locale/fase0-verifica-20260612-101506.txt`. Prossimo: Fase 1 (ruolo eDiscovery).

## 2026-06-12 â€” Correzione autenticazione EXO (rimosso -Device inesistente)

Commit: PENDING-FIRST-COMMIT
File toccati: `scripts/Verify-MailboxState.ps1`, `context/STACK.md`, `context/design-and-security.md`,
`context/deployment.md`, `memory/index.md`, `memory/decisions.md` (ADR-005).
Motivo: l'esecuzione reale ha mostrato che `Connect-ExchangeOnline` (EXO 3.9.2) non ha il parametro
`-Device`: il device-code flow ipotizzato in ADR-003 non esiste nel modulo. Script e documentazione
ora usano l'autenticazione interattiva (in una finestra PowerShell reale) di default e l'app-only
con certificato per l'headless. L'errore WAM originale era dovuto all'host bash del prefisso `!`,
privo di window handle, non a `-Device`. Vedi ADR-005 (supera ADR-003).

## 2026-06-12 â€” Rinomina progetto e registrazione del remote

Commit: PENDING-FIRST-COMMIT
File toccati: `CLAUDE.md`, `.claude/settings.json`, `context/deployment.md`, `_notes/DIARIO.md`.
Motivo: la cartella di progetto Ã¨ stata rinominata da `esporta-mail-statiche` a
`mail-cleaner-exporter` per allinearsi al nome del repository GitHub
`asopranzi-intrawelt/mail-cleaner-exporter`. Aggiornati nome progetto, percorsi assoluti e
registrato il remote di destinazione (`git@github-corp:asopranzi-intrawelt/mail-cleaner-exporter.git`).
Owner reale del repo: `asopranzi-intrawelt` (non `Intrawelt-SaaS` come ipotizzato dalla regola
portabile generica).

## 2026-06-11 â€” Inizializzazione del sistema di progetto + tooling di export

Commit: PENDING-FIRST-COMMIT
File toccati: anatomia di `.claude`, `CLAUDE.md`, `.gitignore`, schede di `context/`, skill
`export-shared-mailbox` con gli script `Verify-MailboxState.ps1` e `Archive-PstExport.ps1`.
Motivo: installazione del sistema portabile di contesto/documentazione (greenfield, senza git per
ora) e creazione del toolkit riusabile per l'esportazione statica di caselle Exchange Online via
Microsoft Purview eDiscovery. Caso d'uso iniziale: caselle condivise `mmartinelli@intrawelt.com`
e `roripa@intrawelt.com`, piene al 100% (primaria + archivio).
Note: corretto il problema di autenticazione WAM ("A window handle must be configured") emerso
lanciando `Connect-ExchangeOnline` da un host senza window handle, adottando il device-code flow
(`-Device`) come default dello script di verifica. Decisione registrata in ADR-002/003.
