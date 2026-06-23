---
generated-from-commit: PENDING-FIRST-COMMIT
generated-from-branch: main
generated-date: 2026-06-11
covers-paths:
  - .claude/skills/export-shared-mailbox/**
last-verified-commit: PENDING-FIRST-COMMIT
---

# Deployment

> Popolare leggendo la configurazione reale di infrastruttura e CI. Commit, push e deploy restano
> operazioni manuali dell'utente.

## Livelli

Non è un servizio: è un toolkit eseguito a mano da un amministratore. Due ambienti di esecuzione
previsti.

- **Oggi — workstation Windows**: gli script girano sul PC dell'amministratore. La destinazione
  di archivio è `V:\`, NAS mappato come unità di rete su questa macchina. Lo staging locale dei
  PST scaricati sta in `D:\mail-cleaner-exporter\export-locale\` (ignorato da git).
- **Futuro — VM su Proxmox in LAN** (da verificare): si valuta di deployare il progetto in una VM
  su un server Proxmox connesso in LAN, per eseguire gli export in modo centralizzato. In quel
  contesto la destinazione di rete sarà passata come percorso UNC verso il NAS
  (`-ArchiveRoot \\<server>\<share>\...`) invece di un'unità mappata, e l'autenticazione sarà
  app-only con certificato (`-AppId`/`-CertificateThumbprint`/`-Organization`), perché in una VM
  senza sessione interattiva l'auth interattiva (broker WAM) non è praticabile. Vedi ADR-005 e ADR-004.

## Comandi

```powershell
# Prerequisito una tantum: modulo Exchange Online (se assente)
Install-Module ExchangeOnlineManagement -Scope CurrentUser

# Fase 0 — verifica read-only (auth interattiva; ESEGUIRE in una finestra PowerShell reale)
.\.claude\skills\export-shared-mailbox\scripts\Verify-MailboxState.ps1

# Fase 4 — archiviazione con checksum, una sottocartella per casella sotto V:\Archivio-Email
.\.claude\skills\export-shared-mailbox\scripts\Archive-PstExport.ps1 `
    -SourceDir .\export-locale\Casella A -ArchiveRoot V:\Archivio-Email -Label Casella A-2026
.\.claude\skills\export-shared-mailbox\scripts\Archive-PstExport.ps1 `
    -SourceDir .\export-locale\Casella B -ArchiveRoot V:\Archivio-Email -Label Casella B-2026
```

Le Fasi 1-3 (export PST) sono manuali nel portale Purview: vedi il runbook in
`.claude/skills/export-shared-mailbox/SKILL.md`.

## Variabili d'ambiente e segreti

Nessuna variabile d'ambiente richiesta e nessun segreto sul disco. L'account di esecuzione deve
avere i ruoli Microsoft 365 adeguati: lettura mailbox per la Fase 0, ruolo Export (gruppo
eDiscovery Manager) per l'export.
