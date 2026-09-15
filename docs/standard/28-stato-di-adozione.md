# 28. Stato di adozione iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-28 |
| Tipo | Capitolo normativo |
| Versione | 1.2.0 |
| Stato | Attivo |
| Responsabile | Amministratore del repository, provvisorio |
| Ultima modifica | 2026-09-15 |
| Approvazione | Registro operativo; baseline normativa ancora proposta |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

| Area | Stato al 2026-09-15 | Azione necessaria |
| --- | --- | --- |
| Standard interno | Completo, proposto | Assegnare responsabili e approvare la baseline |
| Documentazione controllata | Strutturata e verificata automaticamente | Approvare gli information item sostanziali |
| Requisiti | Baseline candidata | Assegnare priorità, metriche e validazione stakeholder |
| Architettura | Baseline candidata con ADR | Chiudere decisioni critiche e accettare ADR-0002 |
| Tracciabilità | Strutturata | Collegare ogni vertical slice a implementazione ed evidenze |
| Controllo versione | Git inizializzato, nessun commit o remote | Creare prima baseline, remote privato e protezioni |
| Codice e test | Baseline eseguibile macOS/iPadOS e package condiviso | Evolvere per vertical slice guidate dai requisiti |
| Sicurezza e privacy | Policy repository e baseline applicativa presenti | Assegnare responsabile, threat model e controlli server-side |
| GitHub | Impostazioni, etichette, ruleset solo/team, bootstrap e audit versionati | Creare il remote privato e applicare il profilo approvato |
| CI | Workflow Xcode 27 configurato e policy Actions dichiarata | Eseguirlo sul remote e rendere `verify` obbligatorio |
| Coverage e benchmark | Regole definite, soglie non ancora approvate | Introdurre con le prime funzioni e hot path reali |
| App Store | Distribuzione non in elenco approvata; identità, metadati, privacy, icona e gate versionati | Completare prodotto, account Apple, URL, screenshot, dispositivi e TestFlight |
| Rilascio | Preflight e packaging senza firma predisposti; pubblicazione intenzionalmente assente | Assegnare identità di firma e superare ogni gate di submission |
| Licenza | BSD-3-Clause attiva | Definire titolarità e modello contributivo |
| Piattaforme iniziali | macOS 27 e iPadOS 27 approvate | Definire classi hardware e parità |
| Backup | Piano definito | Attivare e provare dopo la creazione del remote |

Un elemento `Configurato` non è `Verificato` finché non esiste un'esecuzione osservata nell'ambiente dichiarato. La baseline locale viene verificata da `make verify`; protezioni, backup e CI remote richiedono evidenze successive.
