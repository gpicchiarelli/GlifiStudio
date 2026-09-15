# Descrizione dell'architettura

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AD-001 |
| Tipo | Architecture description |
| Versione | 0.9.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Riferimento | ISO/IEC/IEEE 42010:2022, profilo tailored |

## 1. Entità di interesse e finalità

L'entità di interesse è il sistema software **Glifi Studio**, comprendente prodotto interattivo, API, motore computazionale e accesso headless.

Questa descrizione serve a:

- stabilire i confini e le dipendenze fondamentali;
- rispondere ai concern di correttezza, tracciabilità, scalabilità ed evolvibilità;
- guidare prototipi e decisioni senza cristallizzare implementazioni premature;
- fornire una base verificabile per requisiti, ADR, codice e test.

L'architettura descritta è una baseline candidata. La struttura minima del workspace ora ne realizza i confini principali, mentre i sottosistemi funzionali restano da progettare e implementare.

## 2. Stakeholder e concern

Gli stakeholder sono definiti in GS-VIS-001 e sono ancora da validare.

| ID | Concern | Stakeholder principali | Evidenza attesa |
| --- | --- | --- | --- |
| CO-01 | Correttezza semantica e numerica | ST-01, ST-05 | Test con dataset di riferimento e invarianti esplicite |
| CO-02 | Provenienza e navigazione alla fonte | ST-01, ST-02, ST-06 | Lineage risolvibile e round-trip delle posizioni |
| CO-03 | Scalabilità oltre la memoria disponibile | ST-01, ST-03, ST-05 | Elaborazione incrementale e profiling memoria |
| CO-04 | Prestazioni sull'hardware Apple target | ST-02, ST-03, ST-05 | Benchmark versionati di CPU, memoria e I/O su Mac e iPad |
| CO-05 | Modularità ed evolvibilità | ST-03, ST-04 | Dipendenze acicliche, API ridotte e backend sostituibili |
| CO-06 | Operabilità e diagnosi | ST-02, ST-04 | Errori strutturati, avanzamento, cancellazione e logging |
| CO-07 | Integrità e privacy dei dati | ST-01, ST-06 | Modello delle minacce e policy ancora da definire |
| CO-08 | Riproducibilità | ST-01, ST-05, ST-06 | Versioni e parametri associati a ogni artefatto |
| CO-09 | Usabilità del flusso analitico | ST-01, ST-02 | Validazione del flusso interattivo ancora da pianificare |

## 3. Catalogo dei viewpoint

| ID | Viewpoint | Stakeholder | Concern | Notazione/model kind |
| --- | --- | --- | --- | --- |
| VP-01 | Contesto | ST-01, ST-02, ST-03, ST-06 | CO-02, CO-06, CO-07, CO-09 | Diagramma di contesto testuale; confini e relazioni |
| VP-02 | Decomposizione logica | ST-03, ST-04, ST-05 | CO-01, CO-05, CO-06 | Livelli, moduli e grafo delle dipendenze |
| VP-03 | Dati e lineage | ST-01, ST-03, ST-05, ST-06 | CO-01, CO-02, CO-03, CO-07, CO-08 | Stati derivati, identità, indici e persistenza |
| VP-04 | Runtime ed elaborazione | ST-02, ST-03, ST-05 | CO-03, CO-04, CO-06 | Pipeline, flussi, concorrenza, cancellazione ed errori |
| VP-05 | Tecnologia e deployment | ST-03, ST-04, ST-06 | CO-04, CO-05, CO-07 | Processi locali, framework e backend sostituibili |

Ogni view successiva è governata dal viewpoint con lo stesso numero. La correttezza tra view è specificata nella sezione 9.

## 4. VA-01 — View di contesto

```text
Ricercatore / analista
          │ interazione
          ▼
┌──────────────────── sistema Glifi Studio ────────────────────┐
│ Glifi Studio app → GlifiKit → GlifiCore                    │
│                            ▲                                 │
│ GlifiCLI ─────────────────┘                                 │
└──────────────┬───────────────────────┬────────────────────────┘
               │ legge/importa         │ persiste/riapre
               ▼                       ▼
       Fonti documentali        Progetto e artefatti
               │
               ▼
     Framework e servizi delle piattaforme Apple
```

Le fonti documentali sono input non affidabili. Il progetto persistente conserva identità, configurazioni e artefatti. Non è attualmente prevista una dipendenza necessaria da servizi remoti; questa assenza non costituisce ancora una policy di sicurezza approvata.

## 5. VA-02 — View di decomposizione logica

### 5.1 Livelli

```text
Glifi Studio     applicazioni e presentazione macOS/iPadOS
      ↓
GlifiKit        API pubblica e modelli di interazione
      ↓
GlifiCore       importazione, testo, corpus, ricerca e analisi
      ↓
Servizi          persistenza, calcolo, linguistica, formati e ML
      ↓
Piattaforma      Foundation, Accelerate, Natural Language, Vision,
                 Core ML, Metal e sistema operativo
```

La dipendenza procede dall'esterno verso l'interno. Il grafo deve essere aciclico. Il dominio non dipende dalla GUI; gli algoritmi non dipendono da una persistenza concreta; importer e visualizzazioni non determinano il modello interno.

### 5.2 Confini candidati di GlifiCore

I nomi descrivono responsabilità e non sono ancora target o package approvati.

| Area | Responsabilità | Requisiti principali |
| --- | --- | --- |
| `GlifiDocument` | Identità, fonti, metadati, estrazione e provenienza | RF-002–RF-008 |
| `GlifiText` | Decodifica, Unicode, normalizzazione, segmenti e offset | RF-008–RF-010 |
| `GlifiCorpus` | Viste logiche, selezioni, versioni e sottoinsiemi | RF-001, RF-011–RF-013 |
| `GlifiLinguistics` | Tokenizzazione, lingua, lemmi, POS ed entità | RF-009, RF-010, RF-015 |
| `GlifiIndex` | Vocabolari, posting list e indici specializzati | RF-014 |
| `GlifiSearch` | Query, filtri, concordanze e navigazione | RF-015–RF-018 |
| `GlifiStatistics` | Primitive numeriche e validazione statistica | RF-022, RQ-008 |
| `GlifiAnalysis` | Frequenze, n-grammi e co-occorrenze | RF-019–RF-021 |
| `GlifiPersistence` | Contratti e implementazioni di memorizzazione | RF-001, RF-011, RQ-003, RQ-010 |
| `GlifiCompute` | Scheduling e backend CPU/GPU | RQ-001, RQ-002, RQ-009, RQ-011 |

### 5.3 Mappatura iniziale nell'implementazione

| Elemento | Collocazione | Stato |
| --- | --- | --- |
| Applicazioni native | `Apps/macOS`, `Apps/iPadOS`, `Apps/Shared` | SwiftUI; stato Observation isolato sul Main Actor |
| API pubblica | `Packages/GlifiCore/Sources/GlifiKit` | Contratto minimo di bootstrap |
| Motore | `Packages/GlifiCore/Sources/GlifiCore` | Nucleo minimo indipendente dalla UI |
| Accesso headless | `Packages/GlifiCore/Sources/GlifiCLI` | Eseguibile minimo |
| Verifica | `Packages/GlifiCore/Tests`, `Scripts` | Test e gate locali attivi |

I confini candidati della sezione 5.2 non sono ancora target separati: verranno introdotti soltanto quando responsabilità e dipendenze siano sufficientemente stabili.

## 6. VA-03 — View dei dati e del lineage

### 6.1 Stati documentali

La fonte originale è immutabile dal punto di vista analitico. Le rappresentazioni derivate sono distinte:

```text
S0  sorgente originale
S1  testo estratto
S2  testo normalizzato
S3  segmentazione
S4  tokenizzazione
S5  annotazioni linguistiche
S6  indici e strutture analitiche
```

Ogni passaggio è una trasformazione identificabile. Ogni artefatto dichiara origine, versione, parametri e validità rispetto al corpus.

### 6.2 Identità e rappresentazione

- Documenti, corpus, analisi e artefatti hanno identità logiche stabili.
- Path e nomi visualizzati non costituiscono l'identità.
- Gli offset dichiarano l'unità usata; byte, UTF-16, scalar e grapheme cluster non sono intercambiabili.
- Token e occorrenze usano rappresentazioni compatte e data-oriented.
- Le stringhe ripetute sono internate o sostituite da identificatori.
- `TermID`, `DocumentID` e `CorpusID` sono tipi semanticamente distinti.

### 6.3 Indicizzazione

L'infrastruttura iniziale candidata è un inverted index:

```text
TermID → posting list(DocumentID, frequenza, posizioni, attributi)
```

Le posting list possono essere compresse e lette selettivamente. Delta encoding, variable-byte encoding, bit packing e alternative devono essere confrontati tramite benchmark. Indici specializzati possono servire full-text, lemmi, n-grammi, metadati, co-occorrenze, similarità ed embedding.

### 6.4 Persistenza

La persistenza non determina il dominio. Implementazioni differenti possono essere usate per metadati transazionali, posting list, matrici, cache e fonti. Un eventuale formato binario Glifi è un protocollo indipendente dall'ABI Swift e deve rispettare RQ-010.

Le scelte concrete di persistenza, incorporazione delle fonti e invalidazione sono ancora aperte.

## 7. VA-04 — View runtime ed elaborazione

### 7.1 Pipeline

```text
byte → scalari Unicode → segmenti → token → annotazioni → indice
```

Ogni fase consuma input limitato, produce output progressivo, propaga cancellazione ed errori e rispetta il backpressure. L'uso della memoria dipende principalmente dalla finestra di lavoro e dalle strutture indicizzate, non dalla dimensione complessiva del corpus.

Il memory mapping può essere una tecnica di implementazione, ma non sostituisce il modello incrementale.

### 7.2 Concorrenza

Swift Concurrency è il modello principale. Task, task group e actor devono avere ownership e durata comprensibili. Gli actor definiscono confini di isolamento deliberati e non vengono creati automaticamente per ogni entità.

Le operazioni lunghe espongono avanzamento, cancellazione ed errori strutturati. Il backpressure impedisce la crescita incontrollata delle code e della memoria.

### 7.3 Percorsi di calcolo

Il percorso Swift/CPU costituisce la baseline corretta e testabile. La promozione segue la scala definita da ADR-0008: Accelerate per primitive numeriche e vettoriali, Core ML per modelli con selezione di CPU/GPU/Neural Engine e Metal/MPS per carichi massivamente paralleli. Ogni backend mantiene fallback, osservabilità, cancellazione e confronto sulla stessa semantica.

La selezione dipende da capacità interrogate a runtime e benchmark end-to-end, non dal nome commerciale del chip. Il piano completo è definito in [GS-APL-011](apple/11-calcolo-accelerato-apple-silicon.md).

## 8. VA-05 — View tecnologica e di deployment

### 8.1 Ipotesi operativa corrente

Le applicazioni Glifi Studio eseguono localmente su macOS 27 e iPadOS 27 o successivi. GlifiCLI è disponibile nel package per macOS e per lo sviluppo. L'accesso futuro ai progetti passerà attraverso le API documentali e filesystem consentite dalla piattaforma. Matrice hardware, sandbox, parità delle funzioni e modalità di distribuzione restano decisioni aperte.

L'italiano è la lingua sorgente dell'interfaccia e la lingua analitica predefinita. Il catalogo internazionalizzabile appartiene al livello prodotto e usa chiavi semantiche con localizzazioni iniziali `it`/`en`. Codici lingua, locale e versione del backend attraversano GlifiKit come dati espliciti e non come stato globale implicito; cambiare la lingua dell'interfaccia non cambia la lingua di un corpus.

Entrambe le app includono un privacy manifest condiviso. Il target macOS applica App Sandbox con accesso ai soli file selezionati dall'utente e Hardened Runtime in Release. Capability ulteriori non appartengono alla baseline finché non sono richieste da una funzione approvata.

### 8.2 Tecnologie e ruolo

| Tecnologia | Ruolo candidato | Vincolo |
| --- | --- | --- |
| Swift e Swift Concurrency | Linguaggio, isolamento e pipeline concorrenti | Ownership, cancellazione e backpressure espliciti |
| SwiftUI e Observation | Presentazione e stato osservabile | Solo prodotto; stato UI sul Main Actor |
| AppKit e UIKit | Integrazioni specialistiche di piattaforma | Soltanto target o adattatori dedicati |
| Foundation e Uniform Type Identifiers | File, URL, Unicode, trasferimento e tipi documentali | I/O incrementale e nessuna dipendenza inversa |
| PDFKit, Vision, VisionKit e Image I/O | PDF digitale, OCR e scansione | Provenienza, coordinate e incertezza preservate |
| Natural Language | Backend linguistico iniziale | Contratto sostituibile e validazione italiana |
| Foundation Models e Core AI | Assistenza generativa locale | Funzione opzionale, output non autoritativo e fallback |
| Accelerate | Backend numerico e vettoriale prioritario | Correttezza e benchmark obbligatori |
| Core ML | Inferenza su CPU, GPU e Neural Engine | Modelli versionati e backend sostituibile |
| Metal e Metal Performance Shaders | Backend parallelo specializzato | Solo con beneficio end-to-end misurato |
| SwiftData e formati Foundation | Metadati e payload persistenti separati | Decisione DA-004 e migrazioni verificate |
| Core Spotlight | Ricerca di entità utente nel sistema | Non sostituisce l'indice analitico |
| App Intents e Core Transferable | Automazione, Siri/Shortcuts e scambio tipizzato | Contratti di dominio e permessi stabili |
| BackgroundTasks | Lavoro prolungato e differibile su iPadOS | Progress, checkpoint, scadenza e capability minima |
| Logger, OSSignposter e Instruments | Diagnosi e misura | Privacy dei dati e categorie stabili |
| CloudKit/iCloud e Handoff | Sincronizzazione e continuità | Non adottati prima di DA-017 e della policy privacy |

Il [profilo Apple](apple/README.md) assegna stato, gate e riferimenti a ciascuna tecnologia.

### 8.3 Profilo hardware

La matrice supportata deve descrivere capacità, memoria e comportamento osservato, non soltanto famiglie commerciali. Apple silicon è il profilo primario per il calcolo locale; Glifi Studio usa:

- core CPU general purpose ed efficienti tramite scheduling del sistema;
- primitive vettoriali ed energeticamente efficienti tramite Accelerate;
- GPU tramite Metal/MPS per parallelismo ad alta intensità;
- Neural Engine tramite Core ML;
- memoria unificata con layout data-oriented, riuso dei buffer e copie misurate;
- motori documentali e ML di sistema tramite Vision, Natural Language e Foundation Models.

Un acceleratore non disponibile o non conveniente non deve impedire il completamento dei flussi fondamentali.

## 9. Corrispondenze e invarianti tra le view

| ID | Regola di corrispondenza |
| --- | --- |
| CR-01 | Ogni dipendenza mostrata in VA-02 deve rispettare la direzione dei livelli e non introdurre cicli. |
| CR-02 | Ogni rappresentazione da S1 a S6 in VA-03 deve essere prodotta da un componente di VA-02 e da un passo identificabile di VA-04. |
| CR-03 | Ogni componente che accede a una tecnologia di VA-05 deve mantenere il framework dietro il confine indicato in VA-02. |
| CR-04 | Ogni risultato esposto attraverso VA-01 deve conservare il lineage definito in VA-03. |
| CR-05 | Nessun elemento di GlifiCore in VA-02 può richiedere l'inizializzazione di SwiftUI, AppKit o UIKit in VA-05. |
| CR-06 | Ogni percorso accelerato in VA-04 deve essere confrontabile con una baseline corretta sullo stesso dataset. |
| CR-07 | Ogni dipendenza da una capacità hardware o Apple Intelligence deve avere rilevamento a runtime e comportamento di fallback. |
| CR-08 | Un output probabilistico o generativo non può sostituire silenziosamente un dato osservato o un risultato analitico deterministico. |

## 10. Decisioni e rationale

- [ADR-0001 — Piattaforme native iniziali: macOS e iPadOS](adr/0001-piattaforme-native-macos-ipados.md)
- [ADR-0002 — Separazione tra prodotto e motore](adr/0002-separazione-prodotto-motore.md)
- [ADR-0003 — Toolchain e baseline di sviluppo](adr/0003-toolchain-e-baseline-di-sviluppo.md)
- [ADR-0004 — Italiano come lingua iniziale](adr/0004-italiano-lingua-iniziale.md)
- [ADR-0005 — Interfaccia internazionalizzabile](adr/0005-interfaccia-internazionalizzabile.md)
- [ADR-0006 — Baseline applicativa Apple](adr/0006-baseline-applicativa-apple.md)
- [ADR-0008 — Portafoglio tecnologico Apple e strategia Apple silicon](adr/0008-portafoglio-tecnologico-apple-silicon.md)

Le altre scelte descritte sono baseline candidate oppure ipotesi da validare. Il [Registro delle decisioni aperte](decisioni-aperte.md) identifica le questioni che richiedono ADR ulteriori.

## 11. Lacune della descrizione

- stakeholder e concern non sono ancora validati;
- mancano soglie quantitative e scenari di qualità;
- i confini dei package non sono approvati;
- non sono definite persistenza, formato progetto, offset e invalidazione;
- non esistono ancora view di sicurezza, deployment dettagliato o recovery;
- la coerenza dei confini iniziali è verificata, ma manca ancora una regola automatica per il grafo completo delle dipendenze future.
