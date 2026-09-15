# Roadmap iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-PLAN-001 |
| Tipo | Piano di validazione e sviluppo |
| Versione | 0.7.0 |
| Stato | Proposta |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Riferimento | ISO/IEC/IEEE 15289:2019, profilo tailored |

## Natura del documento

Questa roadmap è una **proposta da validare**. Traduce i principi degli appunti in una sequenza che riduce presto i rischi maggiori: streaming, offset Unicode, identità, persistenza, indicizzazione e separazione tra motore e prodotto.

## 1. Fase 0 — Decisioni e prove di fattibilità

Obiettivo: rendere misurabili i vincoli prima di stabilizzare l'architettura.

- validare i modelli hardware supportati per macOS 27 e iPadOS 27;
- scegliere corpus piccoli, medi e stress per benchmark riproducibili;
- prototipare decodifica incrementale e offset sorgente;
- confrontare alternative per metadati, file binari e posting list;
- definire identità, versioni degli artefatti e regole di invalidazione;
- misurare Natural Language sui casi e sulle lingue prioritarie;
- revisionare GS-MET-001 con competenze statistiche e linguistiche;
- selezionare il sottoinsieme MVP, dataset gold, reference implementation,
  precisione e tolleranze per ogni variante iniziale;
- prototipare `AnalysisDescriptor`, serializzazione canonica e invalidazione su DAG;
- definire una matrice hardware basata su capacità, memoria e stato termico;
- confrontare Swift/CPU, Accelerate, Core ML e Metal sui primi kernel candidati;
- verificare disponibilità, qualità italiana, limite di contesto e fallback di Foundation Models;
- prototipare separatamente metadati SwiftData, payload binari e indice Core Spotlight;
- validare contesto d'uso, profili, compiti e vocabolario italiano con persone
  rappresentative secondo GS-UX-001-13;
- prototipare tassonomia delle intenzioni, CollectionProfile, decision table del
  planner e rule set interpretativi senza stabilizzare API premature;
- confrontare alternative di navigazione macOS/iPadOS su dimensioni, input e
  tecnologie assistive differenti.

Uscita: decisioni registrate, benchmark eseguibili e rischi principali quantificati.

## 2. Fase 1 — Vertical slice headless

Obiettivo: dimostrare l'intera catena senza GUI.

```text
testo UTF-8 → decodifica → normalizzazione → tokenizzazione
             → vocabolario → inverted index → frequenze/query
```

La slice deve includere:

- importazione a flusso di testo semplice;
- identificatori fortemente tipizzati;
- collegamento token-sorgente;
- progetto persistente minimo e riapertura;
- query di frequenza e occorrenza;
- matrice documento-termine sparsa, statistiche descrittive e almeno una
  ponderazione completamente versionata;
- descriptor persistito e reference test indipendente per ogni artefatto;
- cancellazione, errori strutturati, test e benchmark;
- accesso tramite una CLI minimale;
- modello headless minimo di indagine, intenzione, profilo e piano spiegabile;
- fixture che dimostrano `applicable`, `notApplicable`, `unavailable` e
  `insufficientEvidence` senza dipendenza dalla GUI;
- Logger e OSSignposter sulle fasi della pipeline e sui confini di I/O.

Uscita: corpus di riferimento elaborato senza residenza completa in memoria e risultati riproducibili dopo la riapertura.

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
- prima AppEntity e App Intent di sola lettura quando identità e deep link sono stabili.

Uscita: prima applicazione utilizzabile su testo semplice e Markdown.

## 4. Fase 3 — Documenti e corpus ricchi

Obiettivo: estendere acquisizione e analisi preservando la stessa pipeline.

- PDF digitale con pagina e posizione;
- OCR come pipeline distinta e tracciata;
- PDFKit, Vision e Image I/O con confronto su dispositivi reali;
- metadati personalizzati e corpus logici;
- confronto come primitive UX per gruppi, autori, categorie e periodi;
- navigazione per concetti e periodi con filtri, n-grammi e co-occorrenze subordinate;
- keyness, tabelle di contingenza e prime analisi statistiche con effect size e
  multiple testing;
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
