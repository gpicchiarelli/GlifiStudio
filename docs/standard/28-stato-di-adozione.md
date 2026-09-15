# 28. Stato di adozione iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-28 |
| Tipo | Capitolo normativo |
| Versione | 1.10.0 |
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
| Design implementativo | Dieci specifiche GS-DOM–GS-PROD e ADR-0016 definite; baseline 0.1 delimitata | Approvare G1 e costruire i vertical prototype nell'ordine DOM/DAT/ANA/UI/RUN |
| Tracciabilità | Matrice machine-readable attiva su 21 clausole ad alto rischio | Estenderla tramite Definition of Ready a ogni vertical slice |
| Controllo versione | Primo commit pubblicato su `main` nel remote privato canonico | Applicare protezioni server-side quando disponibili |
| Codice e test | Baseline eseguibile macOS/iPadOS, package condiviso, facciata diagnostica e policy runtime coperte da test | Evolvere per vertical slice guidate dai requisiti |
| Toolchain Swift | Apple Swift 6.4, Swift 6 language mode, SwiftPM tools 6.4 e strict concurrency verificati | Rivalutare solo con una toolchain Xcode 27 compatibile o nuova ADR |
| Sicurezza e privacy | GS-SEC-001 completo per asset, trust boundary e THR-001–THR-020; zero telemetria e logging tipizzato | Assegnare responsabile ed eseguire corpus avversario, fuzz, kill test e audit build |
| API e CLI | GS-API-001 pre-1.0 definisce lifecycle, async, failure, stream, exit status e compatibilità; solo status è implementato | Implementare vertical slice e contract test senza promettere ABI prematura |
| Sostenibilità macOS | Decision table Low Power Mode/termica/memoria/lifecycle implementata nel core | Collegare l'adattatore event-driven e acquisire baseline Instruments col primo flusso lungo |
| GitHub | Remote privato, impostazioni, 20 etichette, Dependabot e audit attivi | Abilitare piano per ruleset, Secret Scanning e push protection |
| CI | Workflow Xcode 27 con `swift-style` early-fail, `verify` e cache SPM; esecuzione remota soggetta al budget Actions | Ottenere check verdi su runner `xcode-27` |
| Coverage e benchmark | Regole definite, soglie non ancora approvate | Introdurre con le prime funzioni e hot path reali |
| App Store | Distribuzione non in elenco approvata; identità, metadati, privacy, icona e gate versionati | Completare prodotto, account Apple, URL, screenshot, dispositivi e TestFlight |
| Rilascio | Preflight e packaging senza firma predisposti; pubblicazione intenzionalmente assente | Assegnare identità di firma e superare ogni gate di submission |
| Licenza | BSD-3-Clause attiva | Definire titolarità e modello contributivo |
| Piattaforme iniziali | macOS 27 e iPadOS 27 approvate | Definire classi hardware e parità |
| Backup | Remote primario attivo; piano definito | Configurare copia indipendente e provare il ripristino |

Un elemento `Configurato` non è `Verificato` finché non esiste un'esecuzione osservata nell'ambiente dichiarato. La baseline locale viene verificata da `make verify`; protezioni, backup e CI remote richiedono evidenze successive.
