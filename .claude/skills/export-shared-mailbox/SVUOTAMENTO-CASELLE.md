# Guida allo svuotamento delle caselle (FASE SEPARATA, da autorizzare)

Questa e' una guida, non una procedura da eseguire d'ufficio. Lo svuotamento e' una fase distinta
dall'export, irreversibile, e va eseguita SOLO dopo autorizzazione esplicita e separata, ad archivio
gia' verificato e copiato su rete. La skill `export-shared-mailbox` non cancella nulla; questo
documento descrive come si farebbe quando si decide di procedere. I comandi sono di riferimento.

## Precondizioni da soddisfare prima di toccare qualsiasi cosa

L'archivio deve essere completo, verificato per conteggio item e copiato su rete con SHA256
combacianti (la fase di export di questo progetto lo garantisce; controllare i `checksums.csv` sul
NAS). Va riconfermata l'ASSENZA DI HOLD sulle caselle: con un LitigationHold, un InPlaceHold, un
ComplianceTagHold o un RetentionHold attivo la cancellazione NON libera spazio, perche' i contenuti
restano trattenuti negli Elementi ripristinabili fino alla scadenza dell'hold. Si ricontrolla con la
Fase 0 in sola lettura:

```powershell
.\scripts\Verify-MailboxState.ps1 -Mailboxes 'casella-a@dominio','casella-b@dominio'
```

Serve infine l'autorizzazione del titolare del trattamento. Nel caso d'uso che ha originato il
progetto i soggetti sono ex dipendenti: si applicano le considerazioni GDPR gia' in
`context/compliance-gdpr.md` (base giuridica, conservazione, minimizzazione), e l'azione va
registrata nel registro azioni di quel documento.

## Il vincolo di licenza torna anche qui

Lo svuotamento "pulito" via Microsoft Purview, cioe' `New-ComplianceSearchAction -Purge`, richiede
una Content Search e quindi la stessa licenza E3/E5 che mancava per l'export via eDiscovery (vedi
ADR-007). Senza E3/E5 questa via non e' disponibile. Le opzioni realistiche sono percio' tre.

## Opzione 1 (consigliata se le caselle vanno dismesse del tutto)

Se le caselle non servono piu' (tipico per ex dipendenti gia' archiviati), la via piu' semplice e
che libera TUTTO lo spazio, primaria e archivio, e' rimuovere la casella condivisa. La rimozione e'
soft-deleted per 30 giorni (recuperabile in quella finestra), poi definitiva.

```powershell
# riferimento, NON eseguire senza autorizzazione
Remove-Mailbox -Identity casella-a@dominio        # rimuove la shared mailbox (primaria + archivio)
```

Se invece si vuole conservare l'indirizzo ma eliminare solo l'archivio online ormai archiviato:

```powershell
Disable-Mailbox -Identity casella-a@dominio -Archive   # disabilita e pianifica l'eliminazione dell'archivio
```

## Opzione 2 (svuotare mantenendo la casella attiva, senza licenza)

Da Outlook classico, con il Full Access gia' concesso, si elimina il contenuto delle cartelle e si
svuota "Elementi eliminati". Limite: gli Elementi ripristinabili (dumpster) NON si svuotano del
tutto da Outlook, e lo spazio dell'archivio si libera solo dopo che la conservazione degli elementi
eliminati (Recoverable Items retention, default 14-30 giorni) scade. E' una via parziale e lenta.

## Opzione 3 (Purge via PowerShell, solo se si acquisisce E3/E5)

Con una E3/E5 anche temporanea sull'operatore si puo' usare il purge mirato. Procede a piccoli
blocchi (storicamente max 10 item per casella per azione), quindi va iterato.

```powershell
# riferimento, NON eseguire senza autorizzazione e senza licenza E3/E5
Connect-IPPSSession
New-ComplianceSearch -Name "Svuotamento A" -ExchangeLocation casella-a@dominio
Start-ComplianceSearch -Identity "Svuotamento A"
New-ComplianceSearchAction -SearchName "Svuotamento A" -Purge -PurgeType HardDelete
```

## Dopo lo svuotamento

Rieseguire la Fase 0 in sola lettura per confermare che lo spazio sia stato liberato (item count e
dimensioni scese), e annotare l'azione, la data e l'autorizzazione nel registro di
`context/compliance-gdpr.md`. Conservare i `checksums.csv` e l'export su NAS come prova che la posta
era stata archiviata prima della cancellazione.
