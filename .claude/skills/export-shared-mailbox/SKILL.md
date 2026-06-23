---
name: export-shared-mailbox
description: >
  Runbook riusabile per esportare in modo statico una o piu' caselle di Exchange Online
  (Microsoft 365) in file PST verso una risorsa di rete, come backup prima di liberarne lo spazio.
  Copre la verifica preliminare in sola lettura (dimensioni, hold, statistiche per cartella),
  l'export, la verifica di completezza per CONTEGGIO ITEM e l'archiviazione con checksum SHA256.
  Il metodo operativo predefinito e' l'export da Outlook classico, scelto quando l'operatore non
  ha licenza E3/E5 (necessaria alla nuova eDiscovery); se l'operatore e' licenziato, eDiscovery
  resta l'alternativa server-side. NON cancella ne' svuota le caselle: lo svuotamento e' una fase
  separata, da autorizzare esplicitamente ad archivio verificato. Parametrico su caselle e
  destinazione di rete.
---

# Export statico di caselle Exchange Online verso PST su rete

Procedura per archiviare integralmente una o piu' caselle (primaria piu' archivio online) di
Exchange Online in PST, come backup statico su risorsa di rete, prima di liberarne lo spazio.

Vincolo non negoziabile: questa skill esporta e verifica soltanto. Nessuna cancellazione o
svuotamento va eseguito qui; e' una fase futura, separata, da autorizzare a parte ad archivio
verificato. La verifica degli hold serve a sapere se in futuro la cancellazione liberera' davvero
spazio, non a fare nulla ora.

## Scelta del metodo: Outlook classico vs eDiscovery

Il metodo ideale sarebbe Microsoft Purview eDiscovery, che esporta lato server unendo primaria e
archivio. Dopo i ritiri Microsoft del 2025 (Content Search ed eDiscovery Standard classici fusi
nella nuova esperienza unificata) la nuova eDiscovery richiede pero' una licenza Microsoft 365 E3
o E5 Enterprise per CHIUNQUE lavori ai casi, amministratore incluso, e introduce un billing a
consumo sullo storage. Se l'operatore non ha E3/E5 (verificarlo, vedi Fase 0), eDiscovery non e'
praticabile senza spesa. Vedi ADR-006 e ADR-007 in `memory/decisions.md`.

Il metodo predefinito di questo runbook e' quindi l'export da Outlook classico (Win32), che
funziona con una semplice licenza desktop. Ha un limite noto: l'archivio online non viene messo in
cache e Outlook lo scarica in streaming, percio' su cartelle grandi un export in flusso unico puo'
essere troncato da throttling o cadute di rete. Il runbook lo gestisce con due accorgimenti che
sono diventati regola: export a blocchi (e a tranche per data sulle cartelle grandi e piatte) e
verifica di completezza per conteggio item, mai per dimensione. Vedi ADR-008.

## Prerequisiti

Un account operatore (agente del titolare) con diritti amministrativi sul tenant. Outlook classico
(Win32, incluso nelle licenze Microsoft 365 Apps / Business Standard): NON il "nuovo Outlook", che
non sa esportare PST. Modulo `ExchangeOnlineManagement` per le fasi PowerShell
(`Install-Module ExchangeOnlineManagement -Scope CurrentUser`). Autenticazione interattiva in una
vera finestra PowerShell (il broker WAM richiede una finestra; da host senza window handle si
ottiene "A window handle must be configured"); per l'headless, app-only con certificato. Vedi
ADR-005.

## Fase 0 - Verifica preliminare (sola lettura)

Misurare le caselle e raccogliere i conteggi che serviranno da riferimento di completezza. Lo
script di verifica e' parametrico sulle caselle.

```powershell
.\scripts\Verify-MailboxState.ps1 -Mailboxes 'casella-a@dominio','casella-b@dominio'
# headless (VM): app-only con certificato
.\scripts\Verify-MailboxState.ps1 -Mailboxes ... -AppId <guid> -CertificateThumbprint <thumb> -Organization <tenant>.onmicrosoft.com
```

Annotare per ciascuna casella i conteggi item e le dimensioni di primaria e archivio, e lo stato
hold/retention. Poi estrarre le statistiche PER CARTELLA, che sono la base della verifica di
completezza vera (Fase 3): forniscono la baseline esportabile depurata dalle cartelle di sistema.

```powershell
Get-MailboxFolderStatistics -Identity casella-a@dominio -Archive | Select FolderPath,ItemsInFolder,FolderType | Sort FolderPath | Export-Csv ...\fase0-archivio-A-folders.csv -NoTypeInformation -Encoding UTF8
Get-MailboxFolderStatistics -Identity casella-a@dominio          | Select FolderPath,ItemsInFolder,FolderType | Sort FolderPath | Export-Csv ...\fase0-primaria-A-folders.csv -NoTypeInformation -Encoding UTF8
```

Verificare anche che l'operatore abbia (o non abbia) una licenza E3/E5, per decidere il metodo: si
controllano le licenze via Microsoft Graph (`Get-MgUser ... AssignedLicenses`, mappate con
`Get-MgSubscribedSku`); gli SKU idonei sono `ENTERPRISEPACK`/`SPE_E3` (E3) e
`ENTERPRISEPREMIUM`/`SPE_E5` (E5). In assenza, si procede con Outlook classico.

## Fase 1 - Accesso dell'operatore e preparazione di Outlook

Concedere all'operatore Full Access alle caselle, con auto-mapping, cosi' compaiono in Outlook con
primaria e archivio. E' un'azione reversibile.

```powershell
Connect-ExchangeOnline
Add-MailboxPermission -Identity casella-a@dominio -User operatore@dominio -AccessRights FullAccess -InheritanceType All -AutoMapping $true
```

Alzare il tetto dei file PST nel registro, perche' il PST Unicode si ferma di default a 50 GB e un
archivio pieno puo' avvicinarlo (valori in MB; confermare che la versione di Office sia `16.0`):

```powershell
$k = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\PST'
New-Item -Path $k -Force | Out-Null
Set-ItemProperty -Path $k -Name 'MaxLargeFileSize'  -Type DWord -Value 81920
Set-ItemProperty -Path $k -Name 'WarnLargeFileSize' -Type DWord -Value 79872
```

Aprire Outlook classico e attendere che le caselle condivise e le rispettive voci "Archivio
online - ..." compaiano nel riquadro cartelle (l'auto-mapping puo' richiedere da qualche minuto a
un paio d'ore; un riavvio di Outlook spesso lo accelera). Tenere il PC sveglio per tutta la durata
degli export (`powercfg /change standby-timeout-ac 0`); bloccare lo schermo va bene, sospendere o
disconnettere l'utente no, perche' interrompe l'export in corso.

## Fase 2 - Export a blocchi (e a tranche per data sulle cartelle grandi)

Si esporta da Outlook con File, Apri ed esporta, Importa/esporta, Esporta in un file, File di dati
di Outlook (.pst), salvando nello staging locale `export-locale\` con nomi che identificano la
casella (il nome file e' cio' che la verifica usa per raggruppare). Si esporta la primaria in un
PST unico, e l'archivio NON in un colpo solo ma una cartella di primo livello per volta, perche'
la procedura guidata seleziona un solo nodo (piu' sottocartelle) per export e perche' blocchi piu'
piccoli completano dove il flusso unico cade. Per ogni blocco: selezionare il nodo, lasciare
"Includi sottocartelle", nessun filtro.

Attenzione a selezionare la cartella dal ramo dell'ARCHIVIO online, non da quello della primaria:
i due rami hanno cartelle con lo stesso nome (Posta in arrivo, Posta inviata...). Non esportare le
"Cartelle ricerche" (sono ricerche salvate virtuali, duplicherebbero i conteggi); si saltano anche
le cartelle a zero item e quelle di sistema nascoste (es. PersonMetadata), che non sono posta.

Cartelle grandi e piatte (tipicamente Posta in arrivo e Posta inviata dell'archivio, decine di
migliaia di item senza sottocartelle) NON si esportano in un flusso unico: si spezzano per DATA in
tranche da circa due anni. Nella finestra Filtro la scheda "Messaggi" offre solo periodi relativi,
quindi si usa la scheda "Avanzate": Campo, Campi data/ora, "Inviato" per la posta inviata o
"Ricevuto" per quella in arrivo; Condizione "tra"; Valore nel formato esatto a due valori separati
da " e ", ad esempio:

```
01/01/2019 e 31/12/2020
```

Si aggiunge il criterio all'elenco e si verifica che la riga dica il campo giusto (Inviato o
Ricevuto). Le tranche devono essere contigue e non sovrapposte (una finisce il 31/12, la
successiva inizia il 01/01): la somma dei loro conteggi dovra' eguagliare il conteggio della
cartella sul server, cosi' si esclude sia un buco sia un doppione. Per dimensionare le tranche, in
Outlook si ordina la cartella per data e si leggono il messaggio piu' vecchio e il piu' recente.

Una convenzione di nomi che funziona, dove A e B sono gli pseudonimi delle caselle:

```
CasellaA-primaria.pst
CasellaA-archivio-01-PostaInArrivo.pst
CasellaA-archivio-02-PostaInviata.pst
...
CasellaB-archivio-01a-PostaInviata-2017-2018.pst   (tranche per data)
CasellaB-archivio-01b-PostaInviata-2019-2020.pst
CasellaB-archivio-02a-PostaInArrivo-2020-2021.pst
```

Dopo ogni export, NON fidarsi della scomparsa del pop-up di avanzamento: confermare prima che il
file sia fermo (non sta piu' scrivendo) e poi, soprattutto, verificarne il conteggio item (Fase 3).
Un export interrotto da una caduta di rete lascia un file stabile ma troncato, e mostra spesso un
avviso "problemi alla rete" da chiudere.

## Fase 3 - Verifica di completezza per conteggio item

La completezza si misura per CONTEGGIO ITEM, mai per dimensione: la dimensione del PST non
coincide con quella riportata dal server e un file troncato resta stabile. Lo script apre i PST
via Outlook (COM), somma gli item per file e li raggruppa per casella; opzionalmente confronta i
totali con i conteggi attesi.

```powershell
# conteggio di un singolo PST appena esportato (Outlook puo' anche restare aperto: lo gestisce)
.\scripts\Verify-PstCompleteness.ps1 -NameLike 'CasellaB-archivio-01a-*'
# verifica completa con verdetto per casella
.\scripts\Verify-PstCompleteness.ps1 -LabelMap @{ CasellaA='CasellaA'; CasellaB='CasellaB' } -Expected @{ CasellaA=<n>; CasellaB=<m> }
```

Il confronto probante NON e' col totale grezzo di `Get-MailboxStatistics` (che include item non
esportabili e conta in modo diverso da `Get-MailboxFolderStatistics`, generando falsi "incompleto"
nell'ordine del 3-5 percento), ma con la BASELINE ESPORTABILE: la somma, dai CSV per cartella di
Fase 0, delle sole cartelle visibili dell'utente, ESCLUSE le RecoverableItems* (Deletions,
DiscoveryHolds, Purges, Versions, SubstrateHolds, Recoverable Items), PersonMetadata, Audits, la
radice "Livello superiore archivio informazioni" e le cartelle a 0 item. La prova d'oro e' il
confronto cartella per cartella: ogni blocco PST deve eguagliare il conteggio della sua cartella
sul server, e per le cartelle spezzate la somma delle tranche deve eguagliare il conteggio della
cartella. Uno scarto residuo composto solo da dumpster, cartelle di sistema e qualche item con
data anomala (che il filtro per data non puo' collocare) e' benigno e va annotato.

## Fase 4 - Archiviazione statica con verifica di integrita'

Copiare i PST dallo staging alla destinazione di rete e verificarne l'integrita' con SHA256. Lo
script calcola l'hash in locale, copia, ricalcola a destinazione e confronta, scrivendo
`checksums.csv`. Il filtro `-NameLike` permette di tenere separate le caselle in sotto-cartelle
distinte.

```powershell
.\scripts\Archive-PstExport.ps1 -SourceDir <staging> -ArchiveRoot <dest> -Label CasellaA-2026 -NameLike 'CasellaA*'
.\scripts\Archive-PstExport.ps1 -SourceDir <staging> -ArchiveRoot <dest> -Label CasellaB-2026 -NameLike 'CasellaB*'
```

La destinazione e' parametrica (ADR-004) e accetta sia un'unita' mappata sia un percorso UNC
(`\\server\share`). Se la finestra PowerShell e' elevata (Amministratore), le unita' di rete
mappate dall'utente normale NON sono visibili e si ottiene "Un'unita' con nome 'V' non esiste":
usare il percorso UNC diretto, che non dipende dalla mappatura. Conviene un primo giro con
`-WhatIfCopy`, che elenca i file e crea la cartella di destinazione senza copiare. Verifica finale:
aprire a campione almeno un PST per casella in Outlook e confrontare cartelle e conteggi con la
Fase 0.

## Troubleshooting (problemi reali e soluzioni)

La dimensione stabile non prova la completezza. Un export interrotto lascia il file fermo: sembra
finito ma e' troncato. Si conferma solo col conteggio item contro la baseline esportabile.

Cadute di rete sugli export grandi dell'archivio online. L'archivio non va in cache e viene
scaricato in streaming, quindi un flusso unico lungo (cartella piatta da decine di GB) puo'
troncarsi. Soluzione: tranche per data. Se anche una tranche cade, si rifa' solo quella.

Filtro per data, formato del valore. La condizione "tra" vuole due date separate da " e "
("gg/mm/aaaa e gg/mm/aaaa"); altri formati danno "Immettere il valore nel formato <Valore1> e
<Valore2>". Errore tipico: scrivere le date nei campi "Da..."/"Inviato a..." invece che nella riga
data della scheda Avanzate.

Errore COM 0x80080005 (CO_E_SERVER_EXEC_FAILURE) lanciando lo script di verifica. Capita quando
Outlook e' in uno stato transitorio (appena chiuso e non ancora terminato, un'istanza "fantasma"
lasciata da un run precedente, o una finestra modale aperta) o quando PowerShell gira a un livello
di privilegio diverso da Outlook. Lo script ora si auto-ripulisce (chiude eventuali processi
Outlook, attende, ritenta l'aggancio e chiude la propria istanza in coda); se persiste, chiudere
Outlook manualmente e usare una finestra PowerShell non elevata.

File PST "Device or resource busy" o "E' possibile eseguire una sola versione di Outlook". Sono
sintomi dello stesso processo Outlook fantasma che tiene il file agganciato o blocca un nuovo
avvio: `Get-Process outlook | Stop-Process -Force` e riprovare.

File temporanei orfani. Outlook crea `~<nome>.pst.tmp` durante l'export e li rimuove a fine
operazione; se il processo viene chiuso a forza restano orfani nello staging. Sono spazzatura
(non dati) e si eliminano.

Falso positivo del verdetto a tolleranza. Lo script, se gli si passa il totale grezzo di Fase 0
come atteso, segnala "incompleto" per pochi punti percentuali anche quando l'export e' completo,
perche' quel totale include dumpster e cartelle di sistema non esportabili. Il giudizio corretto e'
contro la baseline esportabile.

## Dopo l'export

Aggiornare il work-log con esito, percorso di archivio e checksum. Lo staging `export-locale\` si
svuota solo dopo la copia su rete verificata; le evidenze (report di completezza, CSV per cartella,
screenshot) si archiviano fuori dal repo, in `_notes/` (locale, non committato), mentre la
narrazione di audit e questa procedura restano nei file versionati. Lo svuotamento delle caselle
resta fuori da questa skill: si pianifica a parte, tenendo conto che con un hold attivo la
cancellazione non libera spazio finche' l'hold non e' gestito.
