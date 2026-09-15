# Pratiche Apple per le applicazioni

| Campo | Valore |
| --- | --- |
| Identificatore | GS-APL-IDX-001 |
| Tipo | Indice delle pratiche Apple |
| Versione | 1.2.0 |
| Stato | Attivo |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | Decisione esplicita dell'iniziatore del progetto |

Questo indice applica le indicazioni Apple pertinenti alle app Glifi Studio per macOS 27 e iPadOS 27. Il progetto sfrutta i componenti hardware e i servizi di sistema che producono un beneficio verificabile, senza aggiungere preventivamente capability, permessi o dipendenze.

La [specifica dei metodi analitici](../metodi-analitici/README.md) definisce la
semantica scientifica. I framework Apple sono backend o strumenti di presentazione:
non sostituiscono formule, precondizioni, provenance o reference test.

La [specifica dell'esperienza](../esperienza-utente/README.md) definisce indagine,
intenzioni, planner, findings e progressive disclosure. I componenti Apple ne
forniscono l'espressione nativa e accessibile senza spostare regole di dominio nelle
view.

La strategia distingue:

- **baseline attiva**: configurata e verificata nello scaffold corrente;
- **da adottare**: tecnologia preferita quando viene implementato il requisito associato;
- **da valutare**: richiede spike, correttezza e benchmark su hardware reale;
- **condizionale**: entra nel prodotto soltanto dopo una decisione o un flusso esplicito;
- **esclusa**: non deve essere introdotta nella nuova implementazione.

## Argomenti

| ID | Documento | Stato di adozione |
| --- | --- | --- |
| GS-APL-001 | [Ciclo di vita e stato SwiftUI](01-ciclo-di-vita-e-stato-swiftui.md) | Baseline attiva |
| GS-APL-002 | [Interfaccia adattiva](02-interfaccia-adattiva.md) | Regole attive; flussi da progettare |
| GS-APL-003 | [Accessibilità](03-accessibilita.md) | Baseline attiva; audit UI progressivi |
| GS-APL-004 | [Privacy e sicurezza](04-privacy-e-sicurezza.md) | Manifest e sandbox attivi |
| GS-APL-005 | [Documenti e accesso ai file](05-documenti-e-accesso-ai-file.md) | Contratto da definire prima dell'importazione |
| GS-APL-006 | [Prestazioni ed energia](06-prestazioni-ed-energia.md) | Regole attive; baseline da misurare |
| GS-APL-007 | [Test e diagnostica](07-test-e-diagnostica.md) | Gate locale attivo; test UI da aggiungere |
| GS-APL-008 | [Firma e distribuzione](08-firma-e-distribuzione.md) | Da completare prima del rilascio |
| GS-APL-009 | [Pipeline documentale e OCR](09-pipeline-documentale-e-ocr.md) | Tecnologie assegnate; implementazione per fasi |
| GS-APL-010 | [Linguistica e intelligenza on-device](10-linguistica-e-intelligenza-on-device.md) | Natural Language prioritario; ML e generazione condizionali |
| GS-APL-011 | [Calcolo accelerato su Apple silicon](11-calcolo-accelerato-apple-silicon.md) | Strategia CPU/Accelerate/GPU/Neural Engine approvata |
| GS-APL-012 | [Persistenza e indicizzazione di sistema](12-persistenza-e-indicizzazione-di-sistema.md) | Alternative assegnate; scelta storage da benchmark |
| GS-APL-013 | [Integrazione di sistema e lavoro prolungato](13-integrazione-di-sistema-e-lavoro-prolungato.md) | App Intents, trasferimento e background pianificati |

## Mappa sintetica delle tecnologie

| Area | Tecnologie Apple principali | Posizione corrente |
| --- | --- | --- |
| Linguaggio e concorrenza | Swift 6, Swift Concurrency, Foundation | Baseline attiva |
| Applicazioni native | SwiftUI, Observation, AppKit/UIKit confinati | Baseline attiva |
| Interazione | NavigationSplitView, Accessibility, SF Symbols, Swift Charts, Core Transferable | GS-UX definita; componenti da adottare per flusso |
| Documenti | Uniform Type Identifiers, PDFKit, Vision, VisionKit, Image I/O, Core Image, Quick Look | Assegnate alle fasi di importazione e OCR |
| Linguistica | Natural Language | Primo backend da validare sull'italiano |
| Calcolo CPU | Accelerate: vDSP, vForce, BLAS/LAPACK, BNNS, vImage | Prima accelerazione da valutare |
| Fondazione scientifica | Swift numerico, Accelerate/BLAS/LAPACK, sparse storage e PRNG controllato | Semantica GS-MET backend-neutral; `GlifiMath` concettuale |
| GPU | Metal, Metal Performance Shaders | Solo con vantaggio end-to-end misurato |
| Machine learning | Core ML su CPU, GPU e Neural Engine | Per modelli specializzati e versionati |
| Generative AI | Foundation Models e Core AI | Assistiva, condizionale, con fallback |
| Dati | SwiftData, formati Foundation versionati, Compression/Apple Archive | Scelta ibrida da prototipare |
| Ricerca di sistema | Core Spotlight, App Entities | Per entità utente, non per l'indice scientifico |
| Automazione | App Intents, Shortcuts, Siri, Apple Intelligence | Dopo la stabilizzazione dei contratti di dominio |
| Lavoro prolungato | BackgroundTasks su iPadOS; task controllati su macOS | Attivazione per operazioni approvate |
| Sicurezza | App Sandbox, Hardened Runtime, Privacy Manifest, Keychain, CryptoKit | Minimo privilegio; estensione per requisito |
| Protezione hardware | Secure Enclave e LocalAuthentication tramite API supportate | Condizionale a chiavi o blocco locale del progetto |
| Rete | URLSession e Network | Disabilitata finché importazione remota o servizi approvati non la richiedono |
| Qualità | Swift Testing, XCTest/XCUITest, Instruments, Logger, OSSignposter, Organizer | Gate attivo e crescita con i flussi |
| Sincronizzazione | CloudKit/iCloud, Handoff | Non adottata finché identità, privacy e conflitti non sono decisi |

Mac Catalyst, ML Compute deprecato, polling perpetuo e dipendenze necessarie da servizi remoti non fanno parte della baseline.

StoreKit, AVFoundation, Speech, ARKit/RealityKit, MapKit, HealthKit, HomeKit e altri framework verticali non sono attualmente necessari: vengono aggiunti al portafoglio soltanto se un requisito di prodotto ne introduce il dominio. Questa esclusione evita permessi, superficie di test e coupling privi di valore per l'analisi testuale.

Le decisioni sono registrate in [ADR-0006](../adr/0006-baseline-applicativa-apple.md) e [ADR-0008](../adr/0008-portafoglio-tecnologico-apple-silicon.md).
