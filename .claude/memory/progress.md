# Work-log

## 2026-06-22 - Completamento Casella B, Fase 4 (copia+SHA256), pulizia e sintesi anonimizzata

Commit: PENDING-FIRST-COMMIT
File toccati: `SKILL.md` (riscritto generico + troubleshooting), i 3 script (default resi generici;
`Verify-PstCompleteness.ps1` reso autopulente sul COM; `Archive-PstExport.ps1` + parametro
`-NameLike`), `memory/index.md`, `context/current-work.md`, `CLAUDE.md` e schede context
(anonimizzazione), nuovi `_notes/audit-export-2026/` (README, MAPPA-PSEUDONIMI, evidenze).

ESITO: export di entrambe le caselle COMPLETO, VERIFICATO e ARCHIVIATO.
- Casella B archivio completato a tranche per data: Posta inviata in 3 tranche (8.683 + 24.780 +
  17.721 = 51.184, esatto vs server); Posta in arrivo in 2 tranche (19.131 + 21.273 = 40.404, meno
  15 messaggi con data "Ricevuto" anomala che nessun filtro per data colloca, benigno); le 5
  cartelle piccole (Calendario 148, Problemi 116, Posta eliminata 77, Cronologia 47, Posta in
  uscita 35) tutte esatte. Saltate 4 micro-cartelle (5 item). Totale PST Casella B 132.717.
- Verifica finale completa: Casella A 127.740, Casella B 132.717; scarto vs Fase 0 interamente
  non-posta (dumpster, sistema, metodo di conteggio).
- Fase 4: `Archive-PstExport.ps1` ha copiato 7 PST (Casella A) e 11 (Casella B) su
  `\\NAS-INTRA3\Public\Archivio-Email\{CasellaA,CasellaB}-2026`, tutti gli SHA256 combacianti,
  `checksums.csv` scritti.

PROBLEMI/SOLUZIONI di questa fase (audit):
- COM 0x80080005 ricorrente all'avvio dello script subito dopo aver chiuso Outlook (processo non
  ancora terminato / istanza fantasma). RISOLTO rendendo lo script autopulente: chiude i processi
  Outlook, attende, ritenta l'aggancio e chiude la propria istanza in coda.
- File `.tmp` orfani: 19 `~*.pst.tmp` (4,2 MB) lasciati dagli Outlook chiusi a forza, eliminati.
- Unita' mappata `V:` non visibile dalla finestra PowerShell elevata (token utente diverso):
  "Un'unita' con nome 'V' non esiste". RISOLTO usando il percorso UNC `\\NAS-INTRA3\Public\...`
  (ADR-004); aggiunto `-NameLike` ad Archive-PstExport per separare le caselle in cartelle distinte.

PULIZIA E ANONIMIZZAZIONE (richiesta utente: tracciare tutto, ma repo anonimizzato):
- `export-locale\` ridotto ai soli PST in transito; report, CSV per cartella e screenshot spostati
  in `_notes/audit-export-2026/` (locale, non committato) con README di riepilogo.
- Pseudonimi Casella A / Casella B applicati a tutti i file versionati; la mappa
  pseudonimo->identita reale (e cartelle NAS reali) vive solo in `_notes/audit-export-2026/
  MAPPA-PSEUDONIMI.md`. Operatore `asopranzi@` lasciato in chiaro (agente del titolare, identita
  git/audit), non e' un soggetto dei dati. `SKILL.md` riscritto come runbook generico con sezione
  troubleshooting; default reali rimossi dagli script. Vedi ADR-008.

## 2026-06-19 - Esecuzione export Outlook (Casella A completa, Casella B in corso): troubleshooting e metodo di verifica

Commit: PENDING-FIRST-COMMIT
File toccati: `scripts/Verify-PstCompleteness.ps1` (fix), nuovi report in `export-locale/`
(completeness-check-*, fase0-*-folders.csv). Esecuzione manuale dell'export da Outlook classico
(operatore asopranzi@ con Full Access auto-mappato sulle due caselle). Tetto PST alzato via registro
(MaxLargeFileSize/WarnLargeFileSize 81920/79872 MB).

ESITO PER CASELLA
- Casella A: COMPLETA e verificata. Primaria 45.340 item; archivio in 6 blocchi per cartella di
  primo livello (Posta in arrivo 57.846, Posta inviata 12.888, Posta eliminata 10.683, Problemi di
  sincronizzazione 720, Calendario 262, Posta indesiderata 1 = 82.400). Ogni blocco confrontato
  con Get-MailboxFolderStatistics e combaciante ALL'ITEM. Totale PST 127.740.
- Casella B: primaria COMPLETA (40.706 item). Archivio IN CORSO: Posta inviata e Posta in arrivo vanno
  rifatte a tranche per data (vedi sotto); restano poi le 5 cartelle piccole.

PROBLEMI INCONTRATI E RISOLUZIONE (audit)
1. "Dimensione stabile" NON prova la completezza. Un export interrotto lascia comunque il file
   fermo: sembra finito ma e' troncato. Lezione operativa: il giudice unico e' il CONTEGGIO ITEM,
   non il peso ne' la sparizione del pop-up. Adottato il controllo di stabilita' solo come segnale
   "non sta piu' scrivendo", non come "completo".
2. Cadute di rete su export grandi dell'archivio online. Casella B Posta inviata troncata due volte
   (29.882 poi 35 GB appeso 5 min con popup "problemi alla rete" -> OK) e Posta in arrivo troncata
   (14.597/40.419). Causa: l'archivio online non va in cache, Outlook lo scarica in streaming e un
   flusso unico lungo (cartella piatta da ~38 GB / 51.184 item) e' esposto a throttling/disconnessioni.
   RISOLUZIONE: spezzare le cartelle piatte grandi per DATA in tranche da ~2 anni (~13 GB ciascuna)
   con il filtro della procedura guidata. 01a (2017-2018) = 8.683 item, OK.
3. Filtro per data: gotcha di UI. La scheda "Messaggi" offre solo periodi relativi (Oggi, questo
   mese...), NON un intervallo personalizzato. Si usa la scheda "Avanzate": Campo -> Campi data/ora
   -> "Inviato"; Condizione "tra"; Valore nel formato esatto "gg/mm/aaaa e gg/mm/aaaa" (due valori
   separati da " e "; altri formati danno errore "Immettere il valore nel formato <Valore1> e
   <Valore2>"). Errore tipico: scrivere le date nei campi "Da..."/"Inviato a..." invece che nella
   riga "Data:" o in Avanzate.
4. Script Verify-PstCompleteness.ps1: due difetti corretti in sessione. (a) L'istanza Outlook
   avviata via COM non veniva chiusa: lasciava il PST BLOCCATO (rm "Device or resource busy") e poi
   impediva di riaprire Outlook ("E' possibile eseguire una sola versione di Outlook"/COM 0x80080005).
   Fix: Quit condizionato (solo se lo script ha avviato l'istanza) + GC; mitigazione operativa:
   tra un export e l'altro si forza `Stop-Process outlook`. (b) Aggiunto parametro -NameLike per
   contare un singolo PST senza aprire i giganti ogni volta. NOTA per la sintesi: la chiusura COM
   resta non perfetta, valutare un taskkill di sicurezza in coda allo script.
5. Falso positivo del verdetto a tolleranza. Lo script confronta col totale grezzo di Fase 0
   (Get-MailboxStatistics) con tolleranza 3%, e segna Casella A "SOSPETTO INCOMPLETO" a -3,13%.
   E' un FALSO POSITIVO: lo scarto e' tutto roba non esportabile. Dimostrazione (Casella A archivio):
   esportati 82.400; non in PST = PersonMetadata 2.136 (cartella di sistema nascosta), Elementi
   ripristinabili (Deletions 27 + DiscoveryHolds 45 + Purges 15 = 87), Attivita' 1, radice 1;
   82.400+2.225 = 84.625 = somma esatta di Get-MailboxFolderStatistics. La differenza fino a 85.867
   (1.242) e' scarto di metodo tra Get-MailboxStatistics e Get-MailboxFolderStatistics, non dati persi.

METODO DI VERIFICA ADOTTATO (prova d'oro, riusabile)
Non fidarsi del totale grezzo di Fase 0. Estrarre per ogni casella `Get-MailboxFolderStatistics
[-Archive] | FolderPath,ItemsInFolder,FolderType` (salvati come fase0-*-folders.csv). La BASELINE
esportabile = somma delle cartelle visibili dell'utente, ESCLUSE le RecoverableItems* (Deletions,
DiscoveryHolds, Purges, Versions, SubstrateHolds, Recoverable Items), PersonMetadata, Audits,
"Livello superiore archivio informazioni" (Root), e le cartelle a 0 item. Si confronta il conteggio
del PST con quella baseline, idealmente cartella per cartella. Baseline calcolate:
- Casella A archivio esportabile = 82.400 (verificato esatto).
- Casella B archivio esportabile = 92.031 (di cui 5 item in 4 micro-cartelle trascurabili Archivio 2,
  Attivita' 1, Bozze 1, Cronologia delle conversazioni 1 -> se saltate, obiettivo 92.026).
- Casella B Posta inviata (cartella piatta) attesa = 51.184, da ricomporre come somma di 01a+01b+01c.
- Casella B Posta in arrivo (cartella piatta) attesa = 40.419, da rifare a tranche per data.

PROSSIMO
Completare le tranche di Casella B Posta inviata (01b 2019-2020, 01c 2021-2023) e Posta in arrivo a
tranche; poi le 5 cartelle piccole dell'archivio Casella B; verifica finale completa; Fase 4
(Archive-PstExport.ps1 su V:); apertura a campione in Outlook. SINTESI FINALE: riscrivere SKILL.md
con la procedura Outlook + queste lezioni (date-split, verifica per cartella, kill Outlook),
aggiornare current-work.md (DoD) e index.md, ed eventualmente ADR-008 sul metodo di verifica.

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
export-locale\ con i conteggi di Fase 0 (Casella A 131.870, Casella B 140.334) con tolleranza 3%;
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
(`casella-a@`, `casella-b@`) sono **ex dipendenti**, che l'ok a procedere Ã¨ stato acquisito in via
informale (Intrawelt NON ha un DPO formalmente nominato â†’ nessun parere RPD scritto; lasciati campi
"autorizzato da" da compilare). Evidenziati i punti 1 (soggetti/natura caselle) e 5 (informativa/
policy, DA CONFERMARE). Inclusi tutti i rilievi GDPR (art. 4 Stat. Lav., linee guida Garante, base
giuridica vs consenso, conservazione, minimizzazione) e un registro append-only delle azioni
Purview. Resta vincolo: solo export, nessuna cancellazione senza autorizzazione separata.

## 2026-06-12 â€” Fase 0 eseguita: misurate le due caselle (nessun hold)

Commit: PENDING-FIRST-COMMIT
File toccati: `context/current-work.md` (numeri di riferimento + DoD).
Esito Fase 0 (read-only) via `Verify-MailboxState.ps1` in finestra PowerShell reale:
- casella-a@intrawelt.com: primaria 16,28 GB / 46.003 item; archivio 50 GB / 85.867 item (pieno).
- casella-b@intrawelt.com: primaria 14,84 GB / 42.910 item; archivio 50 GB / 97.424 item (pieno).
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
Microsoft Purview eDiscovery. Caso d'uso iniziale: caselle condivise `casella-a@intrawelt.com`
e `casella-b@intrawelt.com`, piene al 100% (primaria + archivio).
Note: corretto il problema di autenticazione WAM ("A window handle must be configured") emerso
lanciando `Connect-ExchangeOnline` da un host senza window handle, adottando il device-code flow
(`-Device`) come default dello script di verifica. Decisione registrata in ADR-002/003.
