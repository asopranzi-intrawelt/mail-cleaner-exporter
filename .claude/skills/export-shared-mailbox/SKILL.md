---
name: export-shared-mailbox
description: >
  Runbook riusabile per esportare in modo statico una o più caselle di Exchange Online
  (Microsoft 365) in file PST verso una risorsa di rete, tramite Microsoft Purview eDiscovery.
  Copre la verifica preliminare in sola lettura (dimensioni, hold), l'export PST dal portale e
  l'archiviazione con verifica di integrità. NON cancella né svuota le caselle: lo svuotamento è
  una fase separata e da autorizzare esplicitamente. Parametrico su caselle e destinazione di rete.
---

# Export statico di caselle Exchange Online → PST su rete

Procedura per archiviare integralmente una o più caselle (primaria + archivio online) di Exchange
Online in PST, come backup statico su risorsa di rete, prima di liberarne lo spazio. Il metodo è
Microsoft Purview eDiscovery, scelto per i motivi in `.claude/memory/decisions.md` (ADR-002).

Vincolo non negoziabile: questa skill esporta e verifica soltanto. Nessuna cancellazione o
svuotamento va eseguito qui; è una fase futura, separata, da autorizzare a parte ad archivio
verificato. La verifica degli hold serve a sapere se in futuro la cancellazione libererà davvero
spazio, non a fare nulla ora.

## Prerequisiti

Account amministrativo con: lettura mailbox per la Fase 0, e ruolo Export (gruppo eDiscovery
Manager nel portale Purview) per l'export. Modulo `ExchangeOnlineManagement` installato
(`Install-Module ExchangeOnlineManagement -Scope CurrentUser`). Autenticazione: interattiva di
default, da eseguire in una vera finestra PowerShell / Windows Terminal (il broker WAM richiede una
finestra; da host senza window handle si ottiene "A window handle must be configured"). EXO 3.x non
ha un device-code flow; per l'esecuzione non presidiata usare l'app-only con certificato. Vedi ADR-005.

## Fase 0 — Verifica preliminare (sola lettura)

Eseguire lo script di verifica, parametrico sulle caselle. Default: le due caselle Intrawelt.

```powershell
# In una finestra PowerShell reale (NON via "!")
.\scripts\Verify-MailboxState.ps1
# oppure per altre caselle:
.\scripts\Verify-MailboxState.ps1 -Mailboxes 'tizio@intrawelt.com','caio@intrawelt.com'
# headless (es. VM): app-only con certificato
.\scripts\Verify-MailboxState.ps1 -AppId <guid> -CertificateThumbprint <thumb> -Organization intrawelt.onmicrosoft.com
```

Annotare in `.claude/memory/progress.md` i conteggi item e le dimensioni di primaria e archivio
per ciascuna casella: serviranno come riferimento di completezza dell'export. Registrare anche lo
stato hold/retention.

## Fase 1 — Ruolo eDiscovery

Nel portale Purview (purview.microsoft.com) → Settings → Roles & scopes → Role groups →
eDiscovery Manager: verificare che l'account di esecuzione sia membro (ruolo Export). Anche da
Global Admin il ruolo Export va assegnato esplicitamente.

## Fase 2 — Caso e ricerca eDiscovery

Purview → eDiscovery → Cases → Create case (es. `Archiviazione caselle <nome> <anno>`). Per
ciascuna casella creare una ricerca separata (così si ottengono PST distinti): Searches → New
search → aggiungere la casella condivisa come location della ricerca (l'archivio online associato è
incluso automaticamente e confluisce nello stesso PST). Nessun filtro sulle condizioni, per
catturare tutto. Eseguire la ricerca e verificare che il conteggio item sia coerente con la Fase 0.

Nota (cambiamenti 2025): nella nuova esperienza unificata la scheda **"Origini dati del caso"**
(custodi/origini, a livello di caso) è una funzionalità **eDiscovery Premium**. Senza Premium,
aggiungere le caselle come location **a livello di RICERCA** (durante la New search), oppure usare
il nuovo **"Content search"** (Soluzioni → Content search): entrambi sono di livello Standard.

## Fase 3 — Export PST e download

Sulla ricerca completata: **Export** → assegnare un nome. Opzioni:
- **Export type**: "Export items with items report".
- **Export format**: "Create PSTs for messages".
- **Package size**: max PST 10 GB (split automatico in più PST se serve).
- Selezionare "**Organize data from different locations into separate folders or PSTs**" → un PST
  per casella (primaria + archivio confluiscono comunque in un unico PST per casella).
- Consigliate anche "Include folder and path of the source" e "Condense paths to fit within 256
  characters".

Avviare l'export. Il download NON usa più l'eDiscovery Export Tool ClickOnce (**ritirato il
31/08/2025**): si scarica **direttamente dal portale** in **Process manager → Export packages →
Download packages** (usare Microsoft Edge, consentire i pop-up e i download multipli del sito
Purview). I pacchetti restano scaricabili **14 giorni**, poi vengono eliminati. Export grandi
vengono suddivisi in più PST/zip: è normale. Nota licenza: l'export richiede una licenza M365
**E3/E5** assegnata all'operatore.

Destinazione del download: lo **staging locale** del progetto, `export-locale\` (disco locale
veloce, ignorato da git) — Microsoft stessa consiglia un disco locale e non una share di rete per
il download. La copia verificata su `V:\` la fa la Fase 4.

## Fase 4 — Archiviazione statica con verifica integrità

Copiare i PST dallo staging locale alla destinazione di rete (parametrica) e verificarne
l'integrità con checksum.

```powershell
.\scripts\Archive-PstExport.ps1 -SourceDir ..\..\..\..\export-locale -ArchiveRoot V:\Archivio-Email -Label Ripa-2026
# In VM/altra macchina, destinazione UNC:
.\scripts\Archive-PstExport.ps1 -SourceDir <staging> -ArchiveRoot \\nas\archivio -Label Ripa-2026
```

Lo script copia i PST, calcola gli SHA256 prima e dopo la copia, li confronta e scrive
`checksums.csv` accanto ai file. Verifica finale: aprire almeno un PST per casella in Outlook
(File → Apri ed esporta → Apri file di dati Outlook) e confrontare cartelle e conteggi con la
Fase 0. Conservare anche l'export summary generato da eDiscovery come prova di completezza.

## Dopo l'export

Aggiornare `.claude/memory/progress.md` con esito, percorso di archivio usato e checksum. Lo
svuotamento delle caselle resta fuori da questa skill: si pianifica a parte, tenendo conto che
con un hold attivo la cancellazione non libera spazio finché l'hold non è gestito.
