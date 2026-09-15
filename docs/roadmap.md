# Roadmap iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-PLAN-001 |
| Tipo | Piano di validazione e sviluppo |
| Versione | 0.8.0 |
| Stato | Proposta |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Riferimento | ISO/IEC/IEEE 15289:2019, profilo tailored |

## Natura del documento

Questa roadmap è una **proposta da validare** subordinata alla baseline
[GS-PROD-001](specifiche-di-design/10-product-baseline-mvp.md). Riduce per primi i
rischi di `.glifi`, SpanMap, QueryAST, Analysis DAG, runtime bounded e navigazione;
le capacità post-MVP non entrano accidentalmente nelle prime fasi.

## 1. Fase 0 — Decisioni e prove di fattibilità

Obiettivo: rendere misurabili i vincoli prima di stabilizzare l'architettura.

- validare i modelli hardware supportati per macOS 27 e iPadOS 27;
- approvare GS-DOM/DAT/LNG/QRY/ANA/RUN/UI/VIZ/VAL/PROD e assegnarne gli owner;
- materializzare fixture S/M e corpus gold italiano riproducibili;
- prototipare package `.glifi`, transazione generazionale e recovery;
- provare SpanMap su NFC, Markdown e confini di chunk;
- prototipare store SQLite di sistema, oggetti content-addressed e posting list;
- misurare Natural Language sui casi e sulle lingue prioritarie;
- revisionare GS-MET-001 con competenze statistiche e linguistiche;
- approvare dataset gold, reference implementation, precisione e tolleranze per
  ogni variante Must già selezionata da GS-PROD-001;
- prototipare `AnalysisDescriptor`, serializzazione canonica e invalidazione su DAG;
- definire una matrice hardware basata su capacità, memoria e stato termico;
- confrontare Swift/CPU, Accelerate, Core ML e Metal sui primi kernel candidati;
- verificare disponibilità, qualità italiana, limite di contesto e fallback di Foundation Models;
- prototipare QueryAST, parser bounded e lo stesso piano via GlifiKit/GlifiCLI;
- misurare `ResourceBudget v1`, chunk, code e cancellation su Mac e iPad;
- validare contesto d'uso, profili, compiti e vocabolario italiano con persone
  rappresentative secondo GS-UX-001-13;
- prototipare tassonomia delle intenzioni, CollectionProfile, decision table del
  planner e rule set interpretativi senza stabilizzare API premature;
- confrontare alternative di navigazione macOS/iPadOS su dimensioni, input e
  tecnologie assistive differenti.

Uscita: gate G1 di GS-PROD-001 approvato, decisioni registrate, vertical prototype
di rischio e benchmark eseguibili.

## 2. Fase 1 — Vertical slice headless

Obiettivo: dimostrare l'intera catena senza GUI.

```text
TXT/Markdown UTF-8 → `.glifi` → normalizzazione/SpanMap → `it-token-v1`
                  → inverted index → QueryAST/KWIC → Artifact/Evidence
```

La slice deve includere:

- importazione a flusso di testo semplice;
- identificatori fortemente tipizzati;
- collegamento token-sorgente;
- package persistente con crash recovery e riapertura;
- QueryAST v1, frequenze, occorrenze e KWIC;
- matrice documento-termine sparsa, statistiche descrittive e almeno una
  ponderazione completamente versionata;
- descriptor persistito e reference test indipendente per ogni artefatto;
- cancellazione, errori strutturati, test e benchmark;
- accesso tramite una CLI minimale;
- modello GS-DOM di indagine, intenzione, profilo e piano spiegabile;
- fixture che dimostrano `applicable`, `notApplicable`, `unavailable` e
  `insufficientEvidence` senza dipendenza dalla GUI;
- Logger e OSSignposter sulle fasi della pipeline e sui confini di I/O.

Uscita: gate G2, con corpus di riferimento elaborato senza residenza completa in
memoria e risultati riproducibili dopo la riapertura.

## 3. Fase 2 — Primo flusso interattivo

Obiettivo: offrire un percorso utente completo nelle applicazioni native macOS e iPadOS.

- creazione e apertura di un progetto con più indagini;
- importazione con avanzamento e cancellazione;
- tipi Uniform Type Identifiers e Core Transferable per importazione ed esportazione;
- interfaccia adattiva per mouse, trackpad, tastiera, touch e puntatore;
- domanda iniziale «Che cosa vuoi studiare?» e tassonomia localizzabile delle
  intenzioni, senza catalogo algoritmico come home;
- profilo progressivo della raccolta con problemi e contenuto già utilizzabile;
- prima indagine con piano spiegabile, sintesi editoriale e stati di dati
  insufficienti;
- ricerca, oggetti esplorabili, frequenze e concordanze come approfondimenti;
- catena Finding → Evidence → Fonti → Metodo e lineage di un numero significativo;
- diagnosi comprensibili senza perdere il dettaglio tecnico nel motore;
- validazione di efficacia, comprensione, VoiceOver, tastiera e adattamento;
- relazione Markdown/PDF ed export CSV/JSON con manifest di provenance.

Uscita: gate G3, prima applicazione 0.1 feature-complete su testo semplice e Markdown.

## 4. Fase 3 — Documenti e corpus ricchi

Obiettivo: estendere acquisizione e analisi preservando la stessa pipeline.

- PDF digitale con pagina e posizione;
- OCR come pipeline distinta e tracciata;
- PDFKit, Vision e Image I/O con confronto su dispositivi reali;
- metadati personalizzati e corpus logici;
- confronto come primitive UX per gruppi, autori, categorie e periodi;
- navigazione per concetti e periodi con filtri, n-grammi e co-occorrenze subordinate;
- estensione di keyness e tabelle di contingenza oltre il confronto Must 0.1;
- cronologia ramificata, conservazione di evidenze e prima relazione strutturata;
- primo flusso di codebook e codifica manuale se incluso da DA-002.

## 5. Fase 4 — Analisi avanzata

Obiettivo: aggiungere capacità specialistiche dopo la stabilizzazione dei dati fondamentali.

- servizi linguistici sostituibili valutati su corpus gold;
- indici specializzati, similarità, clustering e reti;
- Correspondence Analysis, PCA/LSA e topic analysis classica versionata;
- riassunto estrattivo deterministico separato dalla generazione;
- embedding e inferenza locale;
- analisi multivariate;
- eventuali percorsi Accelerate e Metal dimostrati dai benchmark.
- Core ML su CPU/GPU/Neural Engine per modelli specializzati versionati;
- funzioni Foundation Models assistive con guided generation, retrieval e fallback;
- ingresso naturale trasformato in interpretazione canonica e piano tipizzato;
- prosa assistita della relazione soltanto sopra findings validi e caveat integri;
- integrazione Core Spotlight e BackgroundTasks per i flussi che la richiedono.

## 6. Principio di rilascio

Ogni fase deve lasciare il sistema corretto, misurabile e utilizzabile. Una funzionalità non è completa se manca almeno uno tra test di correttezza, gestione degli errori, cancellazione per le operazioni lunghe, misura prestazionale pertinente e tracciabilità dell'artefatto prodotto.

I gate G4 e G5 aggiungono dispositivi fisici, accessibilità, performance, sicurezza,
TestFlight, firma, App Review e approvazione unlisted. Nessuna fase successiva può
essere usata per giustificare un placeholder o una regressione nel percorso Must.
