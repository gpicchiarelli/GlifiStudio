# Matrice di tracciabilità

| Campo | Valore |
| --- | --- |
| Identificatore | GS-TRC-001 |
| Tipo | Requirements traceability matrix |
| Versione | 0.14.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Scopo

La matrice collega le fonti iniziali alle necessità degli stakeholder, ai requisiti software, alle parti dell'architettura e alle evidenze di verifica pianificate. Gli identificatori fanno riferimento a [Requisiti](requisiti.md) e [Architettura](architettura.md).

## Tracciabilità end-to-end

| Necessità | Requisiti derivati | View/decisioni architetturali | Verifica pianificata | Stato |
| --- | --- | --- | --- | --- |
| NS-001 Analizzare documenti e corpus | RF-001–RF-004, RF-015–RF-022, RF-025, CV-006 | VA-01, VA-02, ADR-0002, ADR-0004 | TV-001, TV-002, TV-007, TV-008, TV-014 | Italiano approvato; capacità analitiche incomplete |
| NS-002 Verificare risultati sulla fonte | RF-005, RF-009, RF-014, RQ-003 | VA-03, VA-04 | TV-003, TV-006 | Incompleta |
| NS-003 Elaborare corpus massivi | RF-014, RQ-001, RQ-002, RQ-006, RQ-009, RQ-015, RQ-016, RQ-018, CV-013, CV-016 | VA-03, VA-04, ADR-0008 | TV-009, TV-010, TV-019 | Strategia acceleratori approvata; soglie aperte |
| NS-004 Riprendere il lavoro senza ricalcolo inutile | RF-001, RF-011, RQ-004 | VA-03, ADR da definire | TV-001, TV-005 | Incompleta |
| NS-005 Confrontare sottoinsiemi tramite metadati | RF-012, RF-013, RF-018–RF-021 | VA-02, VA-03 | TV-007, TV-008 | Incompleta |
| NS-006 Usare capacità headless e automatizzabili | RF-023, CV-003 | VA-01, VA-02, ADR-0002 | TV-011 | Scaffold e test preliminare presenti |
| NS-007 Ottenere risultati corretti e riproducibili | RF-022, RQ-003, RQ-007–RQ-011, RQ-013–RQ-018, CV-014, CV-016 | VA-03, VA-04, VA-05, ADR-0006, ADR-0008 | TV-004, TV-008, TV-009, TV-012, TV-016, TV-018–TV-020 | Baseline Apple e policy AI attive; verifiche di dominio incomplete |
| NS-008 Lavorare in app native macOS e iPadOS | RF-024, RQ-012, RQ-019–RQ-022, CV-001–CV-005, CV-007–CV-019 | VA-01, VA-02, VA-05, ADR-0001, ADR-0003, ADR-0005, ADR-0006, ADR-0008, ADR-0011 | TV-013, TV-015–TV-025 | Build e packaging baseline; prodotto e submission incompleti |

## Evidenze acquisite

| Evidenza | Verifiche coperte | Esito | Limite |
| --- | --- | --- | --- |
| [GS-VER-001](evidenze/GS-VER-001-bootstrap-ambiente.md) | TV-011 preliminare; TV-013 build baseline | Superato | Non copre flussi funzionali, firma o dispositivi fisici |
| [GS-VER-002](evidenze/GS-VER-002-baseline-linguistica-italiana.md) | TV-014 configurazione iniziale | Superato | Non copre ancora la qualità delle analisi linguistiche italiane |
| [GS-VER-003](evidenze/GS-VER-003-interfaccia-internazionalizzabile.md) | TV-015 catalogo e build `it`/`en` | Superato | Test UI del cambio lingua richiesti quando esisteranno flussi interattivi |
| [GS-VER-004](evidenze/GS-VER-004-baseline-applicativa-apple.md) | TV-016 baseline Apple; predisposizione TV-017/TV-018 | Superato | Audit UI, profiling e dispositivi richiesti con i primi flussi funzionali |
| [GS-VER-005](evidenze/GS-VER-005-ridenominazione-glifi-studio.md) | Regressione TV-013, TV-015 e TV-016 dopo ADR-0007 | Superato | Non copre disponibilità legale del nome, firma o sistemi esterni |
| [GS-VER-006](evidenze/GS-VER-006-portafoglio-tecnologico-apple.md) | Strategia ADR-0008 e predisposizione TV-019–TV-021 | Superato | Non sostituisce benchmark e prove funzionali su dispositivi reali |
| [GS-VER-009](evidenze/GS-VER-009-preflight-app-store.md) | TV-022; baseline di TV-023 e TV-025 | Superato localmente | Packaging senza firma; submission, account Apple, prodotto e dispositivi esclusi |

## Catalogo delle verifiche pianificate

| ID | Metodo | Evidenza attesa |
| --- | --- | --- |
| TV-001 | Test di sistema | Creazione, chiusura e riapertura di un progetto senza perdita di stato |
| TV-002 | Test di importazione | Importazione dei formati approvati con contenuto e metadati attesi |
| TV-003 | Test di round-trip delle posizioni | Dall'occorrenza indicizzata alla porzione corretta della fonte |
| TV-004 | Test di lineage | Ogni risultato espone corpus, trasformazioni, versioni e parametri |
| TV-005 | Test di invalidazione | Una modifica invalida soltanto gli artefatti dipendenti |
| TV-006 | Test PDF/OCR | Distinzione di provenienza e navigazione a pagina/posizione |
| TV-007 | Test funzionale query | Frequenze, ricerca, filtri e concordanze su corpus noto |
| TV-008 | Test numerico | Risultati confrontati con dataset o implementazione di riferimento |
| TV-009 | Benchmark | Throughput, latenza e I/O sui corpus di riferimento |
| TV-010 | Profiling memoria | Memoria entro la soglia approvata su corpus maggiore della memoria assegnata |
| TV-011 | Test headless | Stesso caso d'uso eseguito senza dipendenza dalla GUI |
| TV-012 | Test negativo e robustezza | Input corrotti, errori strutturati e cancellazione controllata |
| TV-013 | Build/test di piattaforma | Build ed esecuzione dei flussi `Must` sulla matrice macOS, iPadOS e hardware approvata |
| TV-014 | Verifica linguistica italiana | Catalogo e regione `it`, default analitico `it`, locale `it_IT` e fixture italiane entro le soglie approvate |
| TV-015 | Verifica internazionalizzazione UI | Chiavi semantiche, cataloghi `it`/`en`, risorse condivise e build di entrambe le app senza modifiche al motore |
| TV-016 | Verifica privacy e capability | Privacy manifest, App Sandbox, Hardened Runtime, entitlement minimi e assenza di capability non autorizzate |
| TV-017 | Audit accessibilità | Accessibility Inspector, VoiceOver, tastiera, Dynamic Type, contrasto, movimento ridotto e testo localizzato sui flussi `Must` |
| TV-018 | Diagnostica e prestazioni UI | Main Thread Checker, Thread Performance Checker, sanitizer applicabili e Instruments sui flussi critici |
| TV-019 | Benchmark e conformità degli acceleratori | Confronto Swift/CPU, Accelerate, Core ML e Metal applicabili per correttezza, tempo, memoria, energia, termica e cancellazione |
| TV-020 | Disponibilità e provenienza dell'intelligenza locale | Prove con modello disponibile/indisponibile, limiti di contesto, fallback, output probabilistico e metadati persistiti |
| TV-021 | Integrazione con il sistema | Test di App Intents, App Entities, Spotlight, Core Transferable, deep link e BackgroundTasks sui target applicabili |
| TV-022 | Packaging App Store | Identità condivisa, version/build, icone, privacy manifest, sandbox, export compliance, analisi e archivi coerenti |
| TV-023 | Audit dichiarazioni | Comportamento, SDK, dati, Required Reason API, privacy manifest, label e policy confrontati sulla stessa build |
| TV-024 | Validazione di prodotto | Flussi `Must`, accessibilità, dispositivi, prestazioni, TestFlight e modello di accesso soddisfano i criteri approvati |
| TV-025 | Validazione di submission | Record, firma, metadati, supporto, App Review e richiesta `unlisted` accettati nei sistemi Apple |

## Lacune note

- Le priorità di rilascio non sono ancora assegnate.
- Esiste soltanto lo scaffold implementativo; le evidenze funzionali di dominio non sono ancora disponibili.
- TV-009, TV-010 e TV-019 richiedono dataset, soglie e hardware di riferimento.
- TV-020 e TV-021 richiedono funzioni di prodotto e contratti persistenti ancora da implementare.
- TV-023–TV-025 richiedono una build funzionalmente completa, identità Apple, URL pubblici e attività nei sistemi Apple.
- La matrice deve essere aggiornata insieme a ogni modifica dei requisiti o dell'architettura.
