---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-12
covers-paths: []
last-verified-commit: PENDING-FIRST-COMMIT
---

# Conformità GDPR e privacy — Export statico caselle ex dipendenti

> Documento di conformità del trattamento "esportazione e archiviazione statica delle caselle
> Exchange Online di ex dipendenti". Titolare del trattamento: Intrawelt. Questo file NON è un
> parere legale: raccoglie i principi applicabili e le decisioni interne, e va validato dal
> referente privacy/legale dell'azienda. I campi marcati DA COMPILARE / DA CONFERMARE vanno
> completati con i dati reali prima di considerare il trattamento documentato.

## Stato dell'autorizzazione

```
Soggetti:                ex dipendenti (vedi punto 1)
Tipo di operazione:      solo export/archiviazione (nessuna cancellazione in questa fase)
Autorizzazione a procedere: ACQUISITA in via informale
DPO / RPD formale:       NON nominato da Intrawelt (nessun RPD formalmente designato)
Parere privacy:          espresso in via informale dalla funzione di riferimento / management
Autorizzato da:          DA COMPILARE (nome e funzione di chi autorizza, es. titolare/legale rappr.)
Data autorizzazione:     DA COMPILARE
Operatore tecnico (eDiscovery): asopranzi@intrawelt.com (Global/Compliance Admin)
```

Nota sull'operatore: si era valutato `it@intrawelt.com` come account funzionale, ma la verifica
(2026-06-12) ha mostrato che **non può autenticarsi** (sign-in non riuscito; probabile shared
mailbox con sign-in disabilitato). Per non bloccare il lavoro si è scelto `asopranzi@intrawelt.com`
(Global/Compliance Admin, sign-in funzionante) come operatore. In futuro, se si vuole un account
funzionale dedicato, andrà abilitato come utente (licenza + sign-in + password) e aggiunto al
gruppo eDiscovery Manager.

Nota di trasparenza: poiché Intrawelt non ha un DPO formalmente nominato, non esiste un parere
scritto di un RPD. L'ok a procedere è una decisione del titolare/management acquisita in via
informale. Raccomandazione: formalizzare la decisione per iscritto (chi autorizza, quando, perché)
e valutare la nomina di un RPD se ricorrono i presupposti dell'art. 37 GDPR.

## Punto 1 (EVIDENZIATO) — Soggetti e natura delle caselle

- `casella-a@intrawelt.com` — **ex dipendente** (Casella A). Casella di tipo SharedMailbox,
  intestata al nominativo della persona.
- `casella-b@intrawelt.com` — **ex dipendente** (Casella B). Casella di tipo SharedMailbox,
  intestata al nominativo della persona.

Essendo intestate a nominativi, è plausibile che fossero caselle **personali poi convertite a
condivise**: il contenuto può quindi includere corrispondenza riferibile alla persona. Questo
alza il livello di attenzione privacy rispetto a una casella puramente funzionale (es. info@).
DA CONFERMARE: se erano nate personali o funzionali.

## Punto 5 (EVIDENZIATO) — Informativa / policy sull'accesso alla posta

DA CONFERMARE: esiste un'**informativa/policy aziendale** che, quando le persone erano in forza,
le informava della possibilità per l'azienda di accedere e/o conservare la posta elettronica
aziendale, e delle modalità?

- Se SÌ: allegarne il riferimento qui (titolo, data, prova di consegna/accettazione). È
  l'elemento di **trasparenza preventiva** che rende difendibile l'accesso.
- Se NO: l'accesso al contenuto è più esposto. Va valutato con il legale se procedere, limitando
  l'operazione a quanto strettamente necessario e documentando con cura finalità e base giuridica.

## Quadro normativo e considerazioni (sintesi di tutti i punti sollevati)

Principio di fondo. La casella è uno strumento aziendale, ma questo NON rende il contenuto
liberamente accessibile. Si applicano insieme:
- **GDPR (Reg. UE 2016/679)**: liceità, trasparenza, proporzionalità, minimizzazione dei dati.
- **Statuto dei Lavoratori, art. 4**: controlli a distanza tramite strumenti di lavoro; un accesso
  massivo alle comunicazioni rientra in quest'ambito e richiede informazione preventiva ai
  lavoratori e proporzionalità.
- **Linee guida del Garante** su posta elettronica e internet nel rapporto di lavoro (e indicazioni
  sui tempi di conservazione dei metadati delle email).

Sul **consenso**. Nel rapporto di lavoro il consenso non è, di norma, una base giuridica valida
(squilibrio di potere) e non è ciò che serve. Serve invece: (a) una **base giuridica** adeguata
(tipicamente legittimo interesse, oppure obbligo legale/contrattuale) e (b) la **trasparenza
preventiva** (l'informativa/policy del punto 5). Quindi la domanda non è "ho il consenso?", ma
"ho base giuridica documentata + informativa preventiva + scopo proporzionato?".

Specificità degli **ex dipendenti**. L'orientamento del Garante è che, alla cessazione, l'account
nominativo vada **disattivato** entro tempi ragionevoli, con eventuale **auto-risponditore** che
reindirizza i contatti, e che il contenuto **non vada conservato/acceduto a tempo indefinito**.
Mantenere attiva e archiviare "per sempre" la casella di un ex dipendente può di per sé essere un
problema privacy, salvo una **finalità specifica e un periodo di conservazione definito** (es.
obblighi fiscali/contabili, contenzioso in corso o probabile, obblighi di legge). Il consenso
dell'ex dipendente non è né richiesto né risolutivo: contano base giuridica, proporzionalità e
termine di conservazione.

## Finalità, base giuridica e conservazione (DA COMPILARE con legale)

```
Finalità dichiarata:     DA COMPILARE (es. continuità operativa / conservazione documentale /
                         adempimento obblighi fiscali-contabili / esigenze difensive)
Base giuridica GDPR:     DA COMPILARE (es. art. 6.1.f legittimo interesse; art. 6.1.c obbligo legale)
Periodo di conservazione: DA COMPILARE (un termine definito, NON "per sempre"; allinearlo agli
                         obblighi di legge applicabili, es. termini civilistici/fiscali)
Minimizzazione:          valutare se serve l'intera casella o solo corrispondenza/documenti
                         aziendali rilevanti
Accesso all'archivio:    chi può accedere a V:\Archivio-Email e con quali permessi (restringere)
```

## Misure adottate a tutela (stato attuale)

- Operazione limitata a **export + verifica**; nessuna cancellazione o svuotamento senza ulteriore
  autorizzazione esplicita e separata (vincolo ribadito in `CLAUDE.md`).
- Verifica Fase 0 (2026-06-12): **nessun hold** sulle due caselle (LitigationHold/InPlaceHolds/
  RetentionHold assenti) → rilevante per definire la conservazione e l'eventuale futura
  cancellazione.
- **Tracciabilità**: ogni azione è registrata sotto (registro azioni Purview) e nel work-log del
  progetto; inoltre Microsoft Purview/eDiscovery scrive nel **log di audit unificato** del tenant,
  dove ricerche ed export restano auditabili.
- Archivio statico su `V:\Archivio-Email\<Casella>-2026`, accesso limitato (DA DEFINIRE i permessi).

## Registro azioni Purview / trattamento (append-only)

| Data | Operatore | Azione | Dettaglio | Esito |
|---|---|---|---|---|
| 2026-06-12 | asopranzi@intrawelt.com | Verifica Fase 0 (read-only) | Get-EXOMailbox/Statistics su casella-a@, casella-b@; lettura retention policy | OK, nessun hold; report in export-locale/ |
| 2026-06-12 | asopranzi@intrawelt.com | Verifica account operatore it@ | it@ non autenticabile (probabile shared mailbox) → operatore = asopranzi@ | Deciso |
| 2026-06-12 | asopranzi@intrawelt.com | Verifica ruolo Export (eDiscovery Manager) | asopranzi è "Amministratore di eDiscovery" (include ruolo Export); anche Tommaso Vezeni admin | OK |
| | | Creazione caso eDiscovery | nome caso: | DA COMPILARE |
| | | Ricerca Export-Casella A | conteggio item: | DA COMPILARE |
| | | Ricerca Export-Casella B | conteggio item: | DA COMPILARE |
| | | Export PST + download | percorso staging: | DA COMPILARE |
| | | Copia verificata su V: | label/checksum: | DA COMPILARE |
