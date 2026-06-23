# Registro delle decisioni architetturali

> Convenzione ADR-lite, append-only. Ogni decisione architetturale non ovvia entra come voce
> numerata con data, stato, contesto, decisione, motivazione e conseguenze. Una decisione non si
> cancella e non si riscrive: quando viene superata, si aggiunge una nuova voce che dichiara di
> superare la precedente e ne cita il numero. Le inferenze non confermate si marcano come da
> verificare e si promuovono a decisione solo quando una fonte le conferma.

## ADR-001 — Adozione del sistema di progetto portabile

Data: 2026-06-11
Stato: accettata
Contesto: il progetto necessita di uno stato interamente recuperabile da un clone e di
documentazione che resti allineata al codice senza rilettura integrale a ogni sessione.
Decisione: adottare il sistema descritto in `.claude/PROJECT-SYSTEM.md`, con motore di
riconciliazione ancorato ai commit e doppio livello documentale tracciato/ignorato.
Motivazione: persistenza strutturale su disco indipendente dalla sessione di chat, e controllo
umano sul versionamento.
Conseguenze: ogni passo significativo aggiorna schede, `last-verified-commit`, snapshot e
work-log; commit e push restano manuali. In questo progetto git non è ancora inizializzato
(scelta in fase di init), quindi i campi commit restano a `PENDING-FIRST-COMMIT`.

## ADR-002 — Metodo di esportazione: Microsoft Purview eDiscovery → PST

Data: 2026-06-11
Stato: accettata
Contesto: le caselle condivise da archiviare sono su Exchange Online e sono piene al 100%, sia
come primaria sia come archivio online. Vanno esportate integralmente in modo affidabile.
Decisione: usare Microsoft Purview eDiscovery (nuova esperienza) per l'export server-side in PST,
non `New-MailboxExportRequest` né l'export via Outlook desktop.
Motivazione: `New-MailboxExportRequest` esiste solo in Exchange on-premises, non in Exchange
Online; il parametro `-Export` di `New-ComplianceSearchAction` è funzionale solo on-prem; Outlook
desktop è inaffidabile su caselle piene e sull'archivio online (limite PST 50 GB di default,
download dell'archivio spesso incompleto). eDiscovery unisce primaria e archivio in un unico PST
per casella ed è gestibile da Compliance Admin.
Conseguenze: serve il ruolo Export (gruppo eDiscovery Manager); il download passa dall'eDiscovery
Export Tool (ClickOnce); i pacchetti restano scaricabili 14 giorni.

## ADR-003 — Autenticazione PowerShell via device-code flow

Data: 2026-06-11
Stato: superata da ADR-005 (il device-code flow non esiste in ExchangeOnlineManagement 3.x)
Contesto: `Connect-ExchangeOnline` (modulo ExchangeOnlineManagement 3.x) lanciato da un host
senza window handle fallisce con "A window handle must be configured" (broker WAM).
Decisione: usare il device-code flow (`Connect-ExchangeOnline -Device`) come default degli script,
con opzione per l'autenticazione interattiva del browser quando si esegue in una sessione GUI.
Motivazione: il device-code flow non richiede un window handle e funziona in console headless,
via SSH e nelle automazioni; è quindi adatto anche al futuro deploy in VM (vedi ADR-004).
Conseguenze: all'avvio lo script mostra un codice e un URL da inserire una volta nel browser.

## ADR-004 — Parametrizzazione della destinazione di rete

Data: 2026-06-11
Stato: accettata
Contesto: oggi l'archivio statico va su `V:\`, un NAS mappato come unità di rete sul PC che lancia
lo script. Le risorse di rete della macchina di esecuzione possono cambiare, e si prevede un
possibile deploy del progetto in una VM su Proxmox connessa in LAN.
Decisione: non cablare il percorso di destinazione; esporlo come parametro (`-ArchiveRoot`) con
default `V:\Archivio-Email`, accettando sia unità mappate sia percorsi UNC (`\\server\share`).
Motivazione: portabilità tra macchine di esecuzione diverse senza modificare lo script.
Conseguenze: in fase di deploy in VM si passerà un `-ArchiveRoot` UNC verso il NAS in LAN; il
percorso effettivo usato va annotato nel work-log di ogni export.

## ADR-005 — Correzione autenticazione: interattiva in finestra reale, app-only per headless (supera ADR-003)

Data: 2026-06-12
Stato: accettata
Contesto: verificato sul campo che `Connect-ExchangeOnline` (ExchangeOnlineManagement 3.9.2) NON
espone alcun parametro `-Device`. I metodi realmente disponibili sono: interattivo (default, broker
WAM), `-Credential`, e app-only con certificato (`-AppId` / `-CertificateThumbprint` /
`-Organization`). L'errore WAM "A window handle must be configured" non dipendeva da `-Device` ma
dall'esecuzione in un host privo di finestra: il prefisso `!` di Claude Code apre una shell bash
senza window handle, quindi il broker WAM non trova una finestra padre.
Decisione: lo script usa l'autenticazione interattiva di default, da eseguire in una vera finestra
PowerShell / Windows Terminal; per l'esecuzione non presidiata (es. VM Proxmox) si usa l'app-only
con certificato tramite `-AppId`, `-CertificateThumbprint`, `-Organization`.
Motivazione: è ciò che il modulo supporta davvero; il device-code non è un'opzione in EXO 3.x.
Conseguenze: rimosso `-Device` da script e documentazione; per il deploy headless va registrata
un'app in Entra ID con certificato e i permessi Exchange/Compliance adeguati.

## ADR-006 — Adeguamento al ritiro degli strumenti eDiscovery classici (2025)

Data: 2026-06-15
Stato: accettata
Contesto: nel 2025 Microsoft ha ritirato gli strumenti previsti dal runbook iniziale: il parametro
PowerShell `New-ComplianceSearchAction -Export` (26/05/2025) e l'eDiscovery Export Tool ClickOnce
(31/08/2025). Inoltre, nella nuova esperienza unificata la scheda "Origini dati del caso"
(custodi/origini) è una funzionalità eDiscovery Premium, che il tenant Intrawelt non possiede.
Decisione: per l'export PST si usa la nuova esperienza unificata in modalità Standard — si
aggiungono le caselle come location a livello di RICERCA (oppure si usa il nuovo "Content search"),
evitando la scheda "Origini dati del caso" (Premium); il download avviene direttamente dal portale
(Process manager → Export packages → Download packages), non più via ClickOnce. L'export richiede
una licenza M365 E3/E5 assegnata all'operatore.
Motivazione: gli strumenti previsti in ADR-002/runbook non esistono più; questa è la via supportata
e disponibile senza Premium.
Conseguenze: aggiornato SKILL.md (Fasi 2-3) e l'index. Per il FUTURO svuotamento resta valido
`New-ComplianceSearchAction -Purge` via PowerShell (non ritirato).

## ADR-007 — Ripiego su export Outlook desktop per vincolo di licenza eDiscovery (supera ADR-002 per questo export; ridimensiona ADR-006)

Data: 2026-06-15
Stato: accettata
Contesto: la verifica della licenza dell'operatore `asopranzi@intrawelt.com` (script ad-hoc
`Check-License.ps1`, sola lettura via Graph) ha rilevato che l'account possiede solo Microsoft 365
Business Standard (SKU `O365_BUSINESS_PREMIUM`, che e' Business Standard nel naming Microsoft) piu'
Defender for Office 365 Plan 2 (`ATP_ENTERPRISE`): nessuna E3/E5. Ricerca su Microsoft Learn
(learn.microsoft.com/purview/edisc-get-started) ha confermato che dopo il ritiro del 31/08/2025 di
Content Search ed eDiscovery (Standard) classici, esiste un'unica nuova esperienza eDiscovery che
richiede esplicitamente una Microsoft 365 E3 o E5 Enterprise per chiunque lavori ai casi,
amministratore incluso. Quindi il workaround "Content search Standard" di ADR-006 non aggira piu' il
requisito di licenza: non c'e' piu' una via Standard a barriera piu' bassa. Inoltre la nuova
eDiscovery introduce un billing a consumo sullo storage dei dati nei casi (edisc-billing), oneroso
per ~131 GB complessivi. Mettere una casella condivisa in hold richiederebbe anche Exchange Online
Plan 2 sulla casella; per un export statico senza hold questo costo e' probabilmente evitabile (punto
marcato come da verificare nelle fonti).
Decisione: per questo export NON si usa eDiscovery. Si esporta da Outlook classico (Win32, incluso in
Business Standard) con Full Access dell'operatore sulle due caselle condivise: primaria in un PST,
archivio online esportato a blocchi su piu' PST. La completezza si verifica con il nuovo script
`Verify-PstCompleteness.ps1`, che confronta gli item dei PST con i conteggi di Fase 0. La Fase 4
(`Archive-PstExport.ps1`, copia su rete con SHA256) resta invariata e valida.
Motivazione: l'utente ha scelto di non sostenere il costo di licenza E3/E5 piu' l'eventuale billing a
consumo per un'operazione una tantum. Outlook desktop e' l'unica via gratuita disponibile con le
licenze presenti. Il rischio noto (scarico incompleto dell'archivio online da 50 GB) e' mitigato
dall'export a blocchi e reso rilevabile dalla verifica dei conteggi contro Fase 0.
Conseguenze: ADR-002 (eDiscovery come metodo) e' superata per questo specifico export; ADR-006 resta
storicamente valida ma il suo workaround Standard e' inefficace senza E3/E5. Tre nuove trappole
operative diventano vincoli: usare Outlook classico e non il "nuovo Outlook" (privo di export PST);
l'archivio online non e' messo in cache e va esportato a blocchi; il limite PST Unicode da 50 GB va
alzato via registro (`MaxLargeFileSize`/`WarnLargeFileSize`). AutoExpandingArchive False su entrambe
le caselle (Fase 0) garantisce che gli archivi siano esportabili da Outlook. Se la verifica dei
conteggi rivelasse un ammanco oltre tolleranza non recuperabile, si rivaluta l'acquisto di una E3
temporanea per tornare a eDiscovery.

## ADR-008 — Verifica di completezza per conteggio item e gestione delle cartelle grandi a tranche

Data: 2026-06-19
Stato: accettata
Contesto: durante l'esecuzione dell'export Outlook (ADR-007) sono emersi due fatti sul campo. Primo,
la dimensione del PST non e' indicatore di completezza: un export interrotto da una caduta di rete
lascia un file stabile ma troncato, che "sembra finito". E' successo due volte su una cartella di
archivio online grande e piatta (Casella B "Posta inviata", ~51.000 item / ~38 GB), che in flusso unico
non completa per throttling/disconnessioni, dato che l'archivio online non e' messo in cache e viene
scaricato in streaming. Secondo, il confronto del totale PST col totale grezzo di Fase 0
(Get-MailboxStatistics) e' inaffidabile: produce falsi positivi perche' quel totale include item
non esportabili (cartelle di sistema come PersonMetadata, Elementi ripristinabili del dumpster) e
perche' Get-MailboxStatistics e Get-MailboxFolderStatistics contano in modo diverso.
Decisione: (1) la completezza si verifica per CONTEGGIO ITEM, non per dimensione; (2) la baseline
non e' il totale di Fase 0 ma la somma delle cartelle realmente esportabili ricavata da
Get-MailboxFolderStatistics, escludendo le RecoverableItems*, PersonMetadata, Audits, la radice e le
cartelle a 0 item, confrontando idealmente cartella per cartella; (3) le cartelle di archivio grandi
e piatte (senza sottocartelle su cui spezzare) si esportano a TRANCHE PER DATA, tramite il filtro
della procedura guidata (scheda Avanzate -> campo "Inviato"/"Ricevuto", condizione "tra", valore
"gg/mm/aaaa e gg/mm/aaaa"), dimensionando le tranche a circa 2 anni / ~13 GB; la somma dei conteggi
delle tranche deve eguagliare il conteggio della cartella sul server (ne' buchi ne' doppioni).
Motivazione: e' l'unico modo per distinguere un export completo da uno troncato e per chiudere la
verifica in modo netto invece che "al limite della tolleranza"; le tranche piccole completano dove
il flusso unico cade e isolano l'eventuale tranche da rifare.
Conseguenze: lo script `Verify-PstCompleteness.ps1` resta utile come screening per file e per
casella, ma il suo verdetto a tolleranza 3% sul totale di Fase 0 e' indicativo, non probante; la
prova e' il confronto con la baseline esportabile. Aggiunto a quello script il parametro -NameLike
(conteggio mirato) e una chiusura COM piu' pulita; resta da rendere la chiusura di Outlook
totalmente affidabile (oggi mitigata con `Stop-Process outlook` tra un export e l'altro). I CSV
`fase0-*-folders.csv`, i report `completeness-check-*` e gli screenshot sono archiviati come evidenza
in `_notes/audit-export-2026/` (locale, non committato, con README di riepilogo); `export-locale/`
resta riservato ai soli PST in transito verso V:.
