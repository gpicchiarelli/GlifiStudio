# 28. Stato di adozione iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-28 |
| Tipo | Capitolo normativo |
| Versione | 1.6.0 |
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
| Fondazione scientifica | GS-MET-001 e ADR-0013 definiti; nessun metodo di dominio ancora implementato | Revisionare formule, scegliere subset MVP, corpus gold e tolleranze |
| Esperienza utente | GS-UX-001 e ADR-0014 definiti; scaffold UI non implementa ancora il paradigma | Prototipare, definire soglie e validare con utenti e tecnologie assistive |
| Tracciabilità | Strutturata | Collegare ogni vertical slice a implementazione ed evidenze |
| Controllo versione | Primo commit pubblicato su `main` nel remote privato canonico | Applicare protezioni server-side quando disponibili |
| Codice e test | Baseline eseguibile macOS/iPadOS e package condiviso | Evolvere per vertical slice guidate dai requisiti |
| Toolchain Swift | Apple Swift 6.4, Swift 6 language mode, SwiftPM tools 6.4 e strict concurrency verificati | Rivalutare solo con una toolchain Xcode 27 compatibile o nuova ADR |
| Sicurezza e privacy | Policy repository e baseline applicativa presenti | Assegnare responsabile, threat model e controlli server-side |
| GitHub | Remote privato, impostazioni, 20 etichette, Dependabot e audit attivi | Abilitare piano per ruleset, Secret Scanning e push protection |
| CI | Workflow Xcode 27 pubblicati; job non avviati per budget Actions | Abilitare budget e ottenere entrambi i check verdi |
| Coverage e benchmark | Regole definite, soglie non ancora approvate | Introdurre con le prime funzioni e hot path reali |
| App Store | Distribuzione non in elenco approvata; identità, metadati, privacy, icona e gate versionati | Completare prodotto, account Apple, URL, screenshot, dispositivi e TestFlight |
| Rilascio | Preflight e packaging senza firma predisposti; pubblicazione intenzionalmente assente | Assegnare identità di firma e superare ogni gate di submission |
| Licenza | BSD-3-Clause attiva | Definire titolarità e modello contributivo |
| Piattaforme iniziali | macOS 27 e iPadOS 27 approvate | Definire classi hardware e parità |
| Backup | Remote primario attivo; piano definito | Configurare copia indipendente e provare il ripristino |

Un elemento `Configurato` non è `Verificato` finché non esiste un'esecuzione osservata nell'ambiente dichiarato. La baseline locale viene verificata da `make verify`; protezioni, backup e CI remote richiedono evidenze successive.
