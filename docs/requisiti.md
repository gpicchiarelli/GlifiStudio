# Specifica dei requisiti software

| Campo | Valore |
| --- | --- |
| Identificatore | GS-SRS-001 |
| Tipo | Software requirements specification |
| Versione | 0.11.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Riferimento | ISO/IEC/IEEE 29148:2018; ISO/IEC 25010:2023, profilo tailored |

## 1. Scopo

Questa specifica traduce le necessità definite in [Visione e principi](visione-e-principi.md) in requisiti del software Glifi Studio. Il perimetro di rilascio e la priorità dei requisiti non sono ancora stati approvati.

## 2. Sistema di interesse

Il sistema di interesse comprende le applicazioni Glifi Studio per macOS e iPadOS, il contratto GlifiKit, il motore GlifiCore e l'accesso headless GlifiCLI. I progetti Glifi Studio, le fonti importate e gli artefatti derivati fanno parte dei dati gestiti dal sistema.

## 3. Fonti

| Codice | Fonte |
| --- | --- |
| A1 | `appunti-1.txt`, documento di progetto e specifica architetturale incompleta |
| A2 | `appunti 2.txt`, documento fondativo di ingegneria del software incompleto |
| VIS | GS-VIS-001, visione e necessità degli stakeholder |
| MET | GS-MET-001, specifica normativa dei metodi analitici |
| UX | GS-UX-001, specifica normativa dell'esperienza utente |

## 4. Interfacce esterne

| ID | Interfaccia | Descrizione | Stato |
| --- | --- | --- | --- |
| IE-001 | Interfaccia macOS | Indagini, importazione, esplorazione per oggetti, confronto, evidenze e relazioni con interazioni desktop native | Specificata concettualmente da GS-UX; da prototipare |
| IE-002 | GlifiKit | Contratto programmatico usato dal prodotto per accedere al motore | Da specificare |
| IE-003 | GlifiCLI | Interfaccia headless per batch, test e automazione | Da specificare |
| IE-004 | Filesystem | Accesso alle fonti, al progetto persistente e agli artefatti | Da specificare |
| IE-005 | Framework Apple | Portafoglio Apple-native per documenti, linguistica, calcolo, dati, ricerca di sistema, automazione e lavoro prolungato, secondo GS-APL-* | Da validare per fase |
| IE-006 | Interfaccia iPadOS | Stesso percorso semantico adattato a touch, puntatore, tastiera, multitasking e finestre ridimensionabili | Specificata concettualmente da GS-UX; da prototipare |

## 5. Requisiti funzionali

`Priorità` indica la priorità di prodotto, non la forza normativa. Tutte le priorità restano da assegnare durante la definizione dell'MVP.

| ID | Requisito | Rationale/fonte | Priorità | Verifica | Stato |
| --- | --- | --- | --- | --- | --- |
| RF-001 | Il sistema **DEVE** creare, salvare, chiudere e riaprire un progetto persistente. | NS-004; A1 | Da assegnare | TV-001 | Baseline candidata |
| RF-002 | Il sistema **DEVE** importare file di testo semplice nelle codifiche approvate. | NS-001; A1 | Da assegnare | TV-002 | Incompleto: codifiche da definire |
| RF-003 | Il sistema **DEVE** importare documenti Markdown preservando contenuto e provenienza. | NS-001; A1 | Da assegnare | TV-002 | Baseline candidata |
| RF-004 | Il sistema **DEVE** estrarre il testo digitale da un PDF e associarlo almeno alla pagina di origine. | NS-001, NS-002; A1 | Da assegnare | TV-002, TV-006 | Baseline candidata |
| RF-005 | Il sistema **DEVE** indicare se un testo deriva da un livello digitale o da OCR. | NS-002, NS-007; A1 | Da assegnare | TV-006 | Baseline candidata |
| RF-006 | Ogni importer **DEVE** produrre una rappresentazione documentale comune con metadati di provenienza. | NS-001, NS-007; A1 | Da assegnare | TV-002, TV-004 | Baseline candidata |
| RF-007 | Il sistema **NON DEVE** modificare implicitamente la fonte originale durante le trasformazioni analitiche. | NS-002, NS-007; A1, A2 | Da assegnare | TV-004 | Baseline candidata |
| RF-008 | Il sistema **DEVE** registrare configurazione e versione di ogni trasformazione di normalizzazione applicata. | NS-007; A1, A2 | Da assegnare | TV-004 | Baseline candidata |
| RF-009 | La tokenizzazione **DEVE** preservare un riferimento non ambiguo alla posizione corrispondente nella fonte o nel testo estratto. | NS-002; A1 | Da assegnare | TV-003 | Incompleto: modello offset aperto |
| RF-010 | GlifiCore **DEVE** consentire implementazioni sostituibili dei servizi di tokenizzazione e analisi linguistica. | NS-001; A1, A2 | Da assegnare | Ispezione API e test di sostituzione | Baseline candidata |
| RF-011 | Il sistema **DEVE** riutilizzare gli artefatti derivati ancora validi dopo la riapertura di un progetto. | NS-004; A1 | Da assegnare | TV-005 | Incompleto: digest, storage e migrazione concreti da definire |
| RF-012 | Un progetto **DEVE** contenere più corpus logici senza richiedere la duplicazione delle fonti. | NS-005; A1 | Da assegnare | Test di sistema | Baseline candidata |
| RF-013 | Il sistema **DEVE** permettere metadati personalizzati utilizzabili per selezione, filtro e raggruppamento. | NS-005; A1 | Da assegnare | TV-007 | Baseline candidata |
| RF-014 | L'indice **DEVE** rappresentare termini e documenti mediante identificatori distinti e recuperare le posizioni delle occorrenze. | NS-001, NS-002, NS-003; A1, A2 | Da assegnare | TV-003, TV-007 | Baseline candidata |
| RF-015 | Il sistema **DEVE** ricercare parole, forme normalizzate, lemmi e frasi nell'ambito selezionato. | NS-001; A1 | Da assegnare | TV-007 | Incompleto: sintassi query aperta |
| RF-016 | Il sistema **DEVE** combinare criteri testuali con espressioni regolari, operatori booleani e filtri sui metadati. | NS-001, NS-005; A1 | Da assegnare | TV-007 | Incompleto: sintassi query aperta |
| RF-017 | Ogni risultato di ricerca **DEVE** includere contesto sufficiente e consentire la navigazione alla fonte. | NS-002; A1 | Da assegnare | TV-003, TV-007 | Baseline candidata |
| RF-018 | Il sistema **DEVE** produrre concordanze KWIC con ampiezza del contesto configurabile, ordinamento e filtri. | NS-001, NS-005; A1 | Da assegnare | TV-007 | Baseline candidata |
| RF-019 | Il sistema **DEVE** calcolare frequenze assolute e relative applicando soglie, stopword e filtri configurati. | NS-001, NS-005; A1 | Da assegnare | TV-007, TV-008 | Baseline candidata |
| RF-020 | Il sistema **DEVE** calcolare n-grammi di parole e di caratteri per i valori di `n` e le soglie configurati. | NS-001; A1 | Da assegnare | TV-007, TV-008 | Baseline candidata |
| RF-021 | Il sistema **DEVE** calcolare co-occorrenze rispetto a una definizione esplicita di contesto e misura di associazione. | NS-001, NS-005; A1 | Da assegnare | TV-008 | Baseline candidata |
| RF-022 | Il sottosistema statistico **DEVE** produrre risultati confrontabili con dataset o implementazioni di riferimento. | NS-007; A1, A2 | Da assegnare | TV-008 | Incompleto: metodi iniziali da definire |
| RF-023 | Le capacità fondamentali di GlifiCore **DEVONO** essere eseguibili senza inizializzare SwiftUI, AppKit o UIKit. | NS-006; A1, A2; ADR-0001 | Da assegnare | TV-011 | Baseline candidata |
| RF-024 | Il sistema **DEVE** fornire applicazioni native operative su macOS e iPadOS per il perimetro `Must` del rilascio. | NS-008; ADR-0001 | Must | TV-013 | Approvato |
| RF-025 | Il sistema **DEVE** offrire la configurazione linguistica italiana nel perimetro `Must` del primo rilascio. | NS-001; ADR-0004 | Must | TV-014 | Approvato |
| RF-026 | Il sistema **DEVE** produrre conteggi e statistiche descrittive di documenti, caratteri, segmenti, frasi, token e type secondo GS-MET-001-04. | NS-001, NS-009; MET | Da assegnare | TV-029 | Baseline candidata |
| RF-027 | Il sistema **DEVE** calcolare diversità lessicale soltanto mediante varianti e finestre definite in GS-MET-001-04. | NS-001, NS-009; MET | Da assegnare | TV-029 | Baseline candidata |
| RF-028 | Il sistema **DEVE** distinguere osservazioni, modelli, fitting e bontà dell'adattamento nelle analisi di frequenza, vocabulary growth, Zipf e Heaps. | NS-009; MET | Da assegnare | TV-029 | Baseline candidata |
| RF-029 | Il sistema **DEVE** rappresentare conteggi e trasformazioni mediante matrici unità-termine sparse con identità e lineage di righe, colonne e celle. | NS-002, NS-003, NS-010, NS-011; MET | Da assegnare | TV-030 | Baseline candidata |
| RF-030 | Il sistema **DEVE** offrire le ponderazioni TF, TF-IDF e BM25 soltanto con formule, smoothing e normalizzazioni versionati. | NS-001, NS-009; MET | Da assegnare | TV-029 | Baseline candidata |
| RF-031 | Il sistema **DEVE** confrontare gruppi mediante keyness conservando popolazioni, frequenze, test, effect size e correzione per confronti multipli. | NS-005, NS-009, NS-010; MET | Da assegnare | TV-031 | Baseline candidata |
| RF-032 | Il sistema **DEVE** rappresentare tabelle di contingenza con osservate, attese, residui, test di indipendenza ed effect size applicabili. | NS-009, NS-010; MET | Da assegnare | TV-031 | Baseline candidata |
| RF-033 | Il sistema **DEVE** produrre Correspondence Analysis con masse, profili, inerzie, coordinate, contributi e qualità della rappresentazione secondo GS-MET-001-10. | NS-009, NS-011; MET | Da assegnare | TV-032 | Baseline candidata |
| RF-034 | Il sistema **DEVE** distinguere co-occorrenze, collocazioni e reti mediante contesto e misura di associazione espliciti. | NS-001, NS-009, NS-011; MET | Da assegnare | TV-029, TV-032 | Baseline candidata |
| RF-035 | Il sistema **DEVE** descrivere la distribuzione interna dei termini mediante document frequency, range e misure di dispersione versionate. | NS-001, NS-009, NS-010; MET | Da assegnare | TV-029 | Baseline candidata |
| RF-036 | Il sistema **DEVE** offrire similarità e distanze distinguendo insiemi, vettori e distribuzioni e applicandone le precondizioni matematiche. | NS-009, NS-011; MET | Da assegnare | TV-032 | Baseline candidata |
| RF-037 | Il sistema **DEVE** produrre cluster soltanto registrando rappresentazione, metrica, algoritmo, parametri, inizializzazione e seed applicabile. | NS-009, NS-011; MET | Da assegnare | TV-032 | Baseline candidata |
| RF-038 | Il sistema **DEVE** supportare un percorso di riduzione dimensionale e topic analysis classico basato almeno su SVD/LSA e predisposto per PCA, NMF e LDA versionati. | NS-011, NS-014; MET | Da assegnare | TV-032, TV-036 | Baseline candidata |
| RF-039 | Il sistema **DEVE** rappresentare reti lessicali come grafi tipizzati con nodi, archi, pesi, direzione, soglie e lineage. | NS-002, NS-011; MET | Da assegnare | TV-032, TV-035 | Baseline candidata |
| RF-040 | Il sistema **DEVE** usare metadati tipizzati e campi temporali come dimensioni di raggruppamento e analisi con mancanti e discretizzazione espliciti. | NS-005, NS-010; MET | Da assegnare | TV-027, TV-029 | Baseline candidata |
| RF-041 | Il sistema **DEVE** valutare i servizi linguistici sostituibili mediante corpus gold e metriche appropriate alla lingua e al compito. | NS-007, NS-013; MET | Da assegnare | TV-033 | Baseline candidata |
| RF-042 | Il sistema **DEVE** consentire riassunti estrattivi riproducibili distinti dagli output generativi non autoritativi. | NS-009, NS-014; MET | Da assegnare | TV-036 | Baseline candidata |
| RF-043 | Il sistema **DEVE** rappresentare codebook, categorie, codifiche di segmenti, annotazioni e memo con identità, versione, autore e lineage. | NS-002, NS-012; MET | Da assegnare | TV-034 | Baseline candidata |
| RF-044 | Il sistema **DEVE** confrontare codificatori mediante una variante dichiarata di Cohen's kappa o Krippendorff's alpha quando ne ricorrono le condizioni. | NS-009, NS-012; MET | Da assegnare | TV-034 | Baseline candidata |
| RF-045 | Il sistema **DEVE** offrire test e intervalli della fondazione statistica soltanto con ipotesi, disegno, precondizioni e metodo di selezione dichiarati. | NS-007, NS-009; MET | Da assegnare | TV-031 | Baseline candidata |
| RF-046 | Il sistema **DEVE** rappresentare le visualizzazioni scientifiche come viste di artefatti analitici indipendenti dalla GUI. | NS-002, NS-009, NS-011; MET | Da assegnare | TV-035 | Baseline candidata |
| RF-047 | Un progetto **DEVE** contenere più indagini persistenti senza duplicare le fonti o alterare i corpus esistenti. | NS-004, NS-016; UX | Da assegnare | TV-037 | Baseline candidata |
| RF-048 | Ogni indagine **DEVE** associare domanda, intenzioni, corpus/versioni, piani, DAG, evidenze, findings, caveat, cronologia e selezione editoriale applicabili. | NS-016, NS-018; UX | Da assegnare | TV-037 | Baseline candidata |
| RF-049 | Il sistema **DEVE** rappresentare le intenzioni analitiche mediante una tassonomia versionata indipendente dalle formulazioni localizzate. | NS-015, NS-023; UX | Da assegnare | TV-038 | Baseline candidata |
| RF-050 | Il primo percorso di un nuovo progetto **DEVE** partire da ciò che la persona vuole studiare e dall'aggiunta di fonti, senza richiedere configurazione algoritmica. | NS-015; UX | Da assegnare | TV-039 | Baseline candidata |
| RF-051 | Il sistema **DEVE** produrre un profilo versionato della raccolta con consistenza, formati, lingue, estrazione, tempo, metadati, duplicazioni, annotazioni e insufficienze. | NS-017, NS-021; UX | Da assegnare | TV-040 | Baseline candidata |
| RF-052 | Durante la preparazione il sistema **DEVE** rendere disponibili progressivamente stato, contenuto utilizzabile, problemi comprensibili e dettaglio tecnico verificabile. | NS-015, NS-022; UX | Da assegnare | TV-039, TV-040 | Baseline candidata |
| RF-053 | Un Analysis Planner **DEVE** derivare un piano tipizzato da profilo, intenzioni, oggetti, capacità e policy versionate. | NS-017; UX | Da assegnare | TV-041 | Baseline candidata |
| RF-054 | Ogni capacità analitica pianificabile **DEVE** dichiarare dati richiesti, precondizioni, qualità minima, costi, dipendenze, output e regola di applicabilità. | NS-009, NS-017; MET, UX | Da assegnare | TV-041 | Baseline candidata |
| RF-055 | Il planner **DEVE** registrare e spiegare inclusioni, esclusioni, rinvii, fallback e condizioni che renderebbero applicabile un metodo. | NS-017, NS-021; UX | Da assegnare | TV-041, TV-042 | Baseline candidata |
| RF-056 | L'intenzione di analisi completa **DEVE** pianificare tutte e sole le famiglie applicabili, informative e sostenibili secondo la policy risolta. | NS-017; UX | Da assegnare | TV-041 | Baseline candidata |
| RF-057 | Il dominio **DEVE** distinguere Evidence, Finding e Caveat e conservarne identità, relazioni, stato e categoria epistemica. | NS-018, NS-021; UX | Da assegnare | TV-043 | Baseline candidata |
| RF-058 | Il sistema **NON DEVE** persistere un finding come risultato proprio senza almeno un'evidenza valida e risolvibile. | NS-002, NS-018; UX | Da assegnare | TV-043 | Baseline candidata |
| RF-059 | Un motore interpretativo deterministico **DEVE** trasformare evidenze in findings soltanto mediante rule set verificabili e versionati. | NS-007, NS-018, NS-021; UX | Da assegnare | TV-043 | Baseline candidata |
| RF-060 | Il sistema **DEVE** mantenere separati dati osservati, trasformazioni, stime, inferenze, interpretazioni deterministiche e contenuti generativi lungo l'intera pipeline. | NS-007, NS-009, NS-018; MET, UX | Da assegnare | TV-027, TV-043 | Baseline candidata |
| RF-061 | Ogni finding **DEVE** offrire la catena navigabile Conclusione → Evidenza → Fonti → Metodo con progressive disclosure. | NS-002, NS-018, NS-019; UX | Da assegnare | TV-044 | Baseline candidata |
| RF-062 | Ogni numero o segno analitico significativo **DEVE** esporre valore, unità, ambito e lineage esatto, contributivo o derivazionale applicabile. | NS-002, NS-019; MET, UX | Da assegnare | TV-044 | Baseline candidata |
| RF-063 | Dopo un piano completo il sistema **DEVE** presentare una sintesi editoriale per famiglie semantiche sostenute dai dati, non un catalogo degli algoritmi eseguiti. | NS-015, NS-018; UX | Da assegnare | TV-042, TV-045 | Baseline candidata |
| RF-064 | Il sistema **DEVE** comunicare la solidità soltanto tramite policy specifiche per famiglia, documentate e versionate, senza confidence score universale. | NS-009, NS-021; MET, UX | Da assegnare | TV-043, TV-045 | Baseline candidata |
| RF-065 | Il sistema **DEVE** sopprimere conclusioni non sostenibili e produrre un caveat o uno stato di evidenza insufficiente con causa e conseguenza. | NS-007, NS-021; UX | Da assegnare | TV-043, TV-045 | Baseline candidata |
| RF-066 | Termine, concetto, documento, segmento, autore, categoria, periodo, gruppo e corpus **DEVONO** essere esplorabili come oggetti senza scelta preventiva di un algoritmo. | NS-015, NS-020; UX | Da assegnare | TV-042 | Baseline candidata |
| RF-067 | Il sistema **DEVE** trattare il confronto tra oggetti compatibili come un'intenzione primaria e selezionare i metodi applicabili. | NS-005, NS-020; UX | Da assegnare | TV-041, TV-042 | Baseline candidata |
| RF-068 | Dopo un finding il sistema **DEVE** poter proporre pochi approfondimenti derivati deterministicamente dal tipo del finding e dall'applicabilità corrente. | NS-017, NS-020; UX | Da assegnare | TV-042, TV-045 | Baseline candidata |
| RF-069 | Un futuro ingresso naturale **DEVE** conservare la domanda originale e produrre un'interpretazione canonica ispezionabile prima del piano. | NS-023; UX | Da assegnare | TV-046 | Baseline candidata |
| RF-070 | La cronologia dell'indagine **DEVE** essere persistente, navigabile e diramabile, distinguendosi da Undo/Redo e dallo stato della finestra. | NS-016; UX | Da assegnare | TV-037, TV-047 | Baseline candidata |
| RF-071 | Il sistema **DEVE** consentire di conservare findings, evidenze e materiali in un'indagine e derivarne una relazione con attribuzione e caveat integri. | NS-016, NS-018; UX | Da assegnare | TV-047 | Baseline candidata |
| RF-072 | macOS e iPadOS **DEVONO** condividere semantica e identità del percorso, adattandone navigazione e interazioni alle convenzioni di piattaforma. | NS-008, NS-022; UX | Must | TV-048 | Approvato |
| RF-073 | Stati, intenzioni, findings, caveat e azioni dell'esperienza **DEVONO** usare identificatori semantici indipendenti dalla lingua e messaggi localizzabili tipizzati. | NS-018, NS-022; UX | Must | TV-015, TV-045 | Approvato |
| RF-074 | Il dettaglio esperto **DEVE** esporre metodi e parametri GS-MET senza trasformare il primo livello dell'esperienza in un catalogo di algoritmi. | NS-009, NS-015, NS-018; MET, UX | Da assegnare | TV-042, TV-045 | Baseline candidata |

## 6. Requisiti di qualità

Le caratteristiche sono classificate secondo il modello ISO/IEC 25010:2023. Le soglie quantitative mancanti impediscono l'approvazione dei requisiti interessati.

| ID | Caratteristica | Requisito | Criterio di accettazione | Verifica | Stato |
| --- | --- | --- | --- | --- | --- |
| RQ-001 | Efficienza prestazionale | Nessun algoritmo fondamentale **DEVE** richiedere che l'intero corpus risieda simultaneamente in memoria. | Completamento su corpus maggiore della memoria assegnata entro la soglia da DA-011 | TV-010 | Incompleto |
| RQ-002 | Efficienza prestazionale | La pipeline **DEVE** applicare backpressure tra produttori e consumatori. | Memoria stabile entro la soglia durante uno sbilanciamento controllato | TV-010 | Incompleto |
| RQ-003 | Affidabilità | Ogni risultato persistente **DEVE** identificare corpus, trasformazioni, versioni e parametri di origine. | Tutti i campi obbligatori presenti e risolvibili | TV-004 | Baseline candidata |
| RQ-004 | Manutenibilità | L'identità persistente di documenti, corpus e analisi **NON DEVE** dipendere dal pathname o dal nome visualizzato. | Spostamento e ridenominazione non alterano l'identità | TV-001 | Baseline candidata |
| RQ-005 | Manutenibilità | Le dipendenze tra moduli **DEVONO** formare un grafo aciclico verificato automaticamente. | Controllo architetturale superato in CI | Ispezione automatica | Baseline candidata |
| RQ-006 | Efficienza prestazionale | Le occorrenze massive **NON DEVONO** richiedere un oggetto heap o una copia della stringa per ogni token. | Profilo allocazioni conforme alla rappresentazione approvata | TV-010 | Incompleto |
| RQ-007 | Affidabilità | Errori di input, I/O, formato, consistenza e invarianti **DEVONO** essere distinguibili programmaticamente. | Test negativi ricevono la categoria attesa | TV-012 | Baseline candidata |
| RQ-008 | Adeguatezza funzionale | Gli algoritmi statistici **DEVONO** rispettare le tolleranze numeriche approvate sui dataset di riferimento. | Tutti i casi di riferimento entro tolleranza | TV-008 | Incompleto |
| RQ-009 | Efficienza prestazionale | Throughput, latenza, memoria e I/O **DEVONO** essere misurati su corpus e hardware versionati. | Report benchmark riproducibile associato alla build | TV-009 | Incompleto |
| RQ-010 | Affidabilità | Ogni formato persistente proprietario **DEVE** essere versionato, validabile e resistente a input corrotti. | Round-trip, compatibilità e casi corrotti superati | TV-012 | Baseline candidata |
| RQ-011 | Affidabilità | Ogni operazione lunga **DEVE** supportare cancellazione controllata e propagazione strutturata degli errori. | Cancellazione senza progetto parzialmente valido o task orfani | TV-012 | Baseline candidata |
| RQ-012 | Capacità di interazione | Ogni flusso `Must` **DEVE** superare l'audit automatico di accessibilità e una verifica manuale VoiceOver e tastiera. | Nessun problema bloccante; problemi residui classificati | TV-017 | Incompleto: flussi non implementati |
| RQ-013 | Efficienza prestazionale | I/O, parsing e analisi non banali **NON DEVONO** bloccare il Main Actor. | Nessuna segnalazione pertinente del Thread Performance Checker sui flussi `Must` | TV-018 | Baseline candidata |
| RQ-014 | Protezione | L'app **NON DEVE** tracciare persone o raccogliere dati finché non esiste una decisione approvata e una dichiarazione coerente. | Manifest senza tracking o raccolta e nessun comportamento difforme | TV-016 | Approvato |
| RQ-015 | Efficienza prestazionale | Un backend Accelerate, Core ML o Metal **DEVE** diventare predefinito soltanto se migliora il flusso end-to-end sulla matrice hardware approvata senza violare le tolleranze di correttezza. | Benchmark confrontabile con baseline Swift/CPU e tolleranze superate | TV-019 | Approvato |
| RQ-016 | Compatibilità | Ogni funzione che dipende da un acceleratore o da Apple Intelligence **DEVE** rilevare la disponibilità a runtime e offrire il fallback approvato. | Tutti i casi disponibili, indisponibili, limitati e cancellati hanno esito definito | TV-019, TV-020 | Approvato |
| RQ-017 | Affidabilità | Ogni risultato probabilistico persistito **DEVE** distinguere modello, versione logica, configurazione, input di contesto e natura non deterministica. | Provenienza completa e risultato distinguibile dai dati osservati | TV-004, TV-020 | Approvato |
| RQ-018 | Efficienza prestazionale | Elaborazioni lunghe **DEVONO** mantenere responsiva l'interfaccia e reagire a cancellazione, scadenza, memoria insufficiente e vincoli termici. | Nessun hang; checkpoint e uscita controllata nei casi della matrice | TV-010, TV-018, TV-019 | Approvato |
| RQ-019 | Capacità di interazione | Entità e azioni esposte a Spotlight, App Intents o trasferimento di sistema **DEVONO** preservare identità, autorizzazioni, localizzazione e navigazione al contenuto corretto. | Test di indicizzazione, intent, deep link e trasferimento su entrambe le piattaforme applicabili | TV-021 | Baseline candidata |
| RQ-020 | Adeguatezza funzionale | Una build candidata App Store **DEVE** offrire valore autonomo, flussi `Must` completi e contenuti finali, senza placeholder o schermate puramente dimostrative. | Audit di funzionalità minima, metadati coerenti e nessun blocco P0/P1 | TV-024, TV-025 | Incompleto: prodotto ancora scaffold |
| RQ-021 | Protezione | Comportamento reale, privacy manifest, dichiarazioni App Store e privacy policy **DEVONO** descrivere lo stesso trattamento di dati, SDK e Required Reason API. | Inventario riesaminato sulla build candidata senza difformità | TV-023 | Baseline candidata |
| RQ-022 | Protezione | Se il pubblico è ristretto, l'app **DEVE** applicare autenticazione e autorizzazione indipendenti dal possesso del link App Store non in elenco. | Accesso negato a soggetto non autorizzato anche con link valido | TV-024 | Incompleto: DA-024 aperta |
| RQ-023 | Affidabilità | Ogni artefatto analitico persistibile **DEVE** avere un `AnalysisDescriptor` completo secondo GS-MET-001-01. | Round-trip e completezza semantica su tutti i tipi di artefatto | TV-027 | Baseline candidata |
| RQ-024 | Manutenibilità | Le dipendenze analitiche **DEVONO** formare un DAG con invalidazione transitiva limitata ai discendenti effettivi. | Suite su grafi ramificati senza riuso scorretto o ricalcolo estraneo | TV-027 | Baseline candidata |
| RQ-025 | Affidabilità | Ogni algoritmo **DEVE** dichiarare e rispettare una classe di determinismo, una politica numerica e il seed applicabile. | Ripetizioni e backend conformi a GS-MET-001-03 | TV-028 | Baseline candidata |
| RQ-026 | Adeguatezza funzionale | Ogni famiglia di test multipli **DEVE** conservare p-value grezzi e una correzione approvata senza ridefinire la famiglia a posteriori. | Fixture Bonferroni/BH e audit del descrittore | TV-031 | Baseline candidata |
| RQ-027 | Adeguatezza funzionale | Ogni metodo scientifico **DEVE** essere validabile contro proprietà, dataset o implementazioni indipendenti. | Reference suite versionata per ogni variante resa disponibile | TV-026, TV-029–TV-036 | Baseline candidata |
| RQ-028 | Affidabilità | Ogni valore o proposizione analitica **DEVE** distinguere dato osservato, trasformato, stimato, inferito, annotato, interpretato deterministicamente o generativo. | Classificazione preservata in persistenza, API, export e UI | TV-027, TV-035, TV-043 | Baseline candidata |
| RQ-029 | Adeguatezza funzionale | Un backend linguistico **NON DEVE** essere promosso come supportato per una lingua senza soglie approvate e risultati su corpus di riferimento. | Report per lingua, servizio, dominio e versione | TV-033 | Incompleto: DA-008 aperta |
| RQ-030 | Capacità di interazione | I flussi primari **DEVONO** raggiungere soglie approvate di efficacia, efficienza e comprensione con utenti rappresentativi. | Protocollo, campione, compiti e soglie definiti prima dello studio | TV-039, TV-045 | Incompleto: DA-026 aperta |
| RQ-031 | Capacità di interazione | Le persone **DEVONO** distinguere finding, evidenza, caveat, associazione e causalità entro le soglie di comprensione approvate. | Test di comprensione e calibrazione senza blocchi critici | TV-045 | Incompleto: DA-026 aperta |
| RQ-032 | Capacità di interazione | Aggiornamenti progressivi **NON DEVONO** perdere selezione, focus o posizione di lettura senza una transizione annunciata. | Test UI, tastiera e VoiceOver su aggiornamenti e invalidazioni | TV-044, TV-048 | Baseline candidata |
| RQ-033 | Affidabilità | Stato persistente dell'indagine, cache, stato effimero e stato per-scena **DEVONO** essere separati e recuperabili secondo il rispettivo contratto. | Riapertura, crash simulato, cache eliminata e ripristino di più scene | TV-037, TV-047 | Baseline candidata |
| RQ-034 | Compatibilità | Lo stesso oggetto e la stessa azione semantica **DEVONO** conservare identità ed effetto tra macOS e iPadOS. | Test contrattuali condivisi e scenari UI specifici di piattaforma | TV-048 | Baseline candidata |
| RQ-035 | Affidabilità | A parità di input, capability e policy, il planner **DEVE** produrre lo stesso piano ordinato e la stessa motivazione strutturata. | Decision table e ripetizioni deterministiche | TV-041 | Baseline candidata |
| RQ-036 | Affidabilità | L'interpretazione strutturata **DEVE** essere riproducibile senza un modello generativo e preservare ogni caveat applicabile. | Reference rule set, test negativi e confronto della struttura | TV-043 | Baseline candidata |
| RQ-037 | Capacità di interazione | Il lineage interattivo **DEVE** essere disponibile con mouse, touch, tastiera e VoiceOver senza falsificare la classe di reversibilità. | Round-trip equivalente per modalità di input e tecnologia assistiva | TV-044 | Baseline candidata |
| RQ-038 | Capacità di interazione | Ogni flusso `Must` dell'indagine **DEVE** essere completabile con VoiceOver e Full Keyboard Access sulle piattaforme applicabili. | Audit end-to-end con nessun blocco di severità critica | TV-017, TV-048 | Incompleto: flussi non implementati |
| RQ-039 | Efficienza prestazionale | Preparazione e analisi **DEVONO** mostrare contenuto progressivo e consentire altro lavoro senza bloccare il Main Actor. | Profiling e prova di cancellazione/attività concorrente sui corpus approvati | TV-018, TV-040, TV-048 | Baseline candidata |
| RQ-040 | Affidabilità | Una relazione **NON DEVE** contenere findings, valori o fonti assenti dalla revisione dell'indagine da cui deriva. | Confronto strutturale completo e test di output generativo ostile | TV-047 | Baseline candidata |

## 7. Vincoli di progetto

| ID | Vincolo | Fonte | Verifica | Stato |
| --- | --- | --- | --- | --- |
| CV-001 | Le piattaforme iniziali del prodotto **DEVONO** essere macOS e iPadOS. | NS-008; ADR-0001 | TV-013 | Approvato |
| CV-002 | Swift **DEVE** essere il linguaggio principale del prodotto e del motore. | A1, A2; ADR-0001 | Ispezione build | Baseline candidata |
| CV-003 | GlifiCore **NON DEVE** importare SwiftUI, AppKit o UIKit. | NS-006; ADR-0001, ADR-0002 | TV-011 | Approvato |
| CV-004 | Le dipendenze specifiche di AppKit e UIKit **DEVONO** restare confinate nei rispettivi target o adattatori di piattaforma. | NS-008; ADR-0001 | Ispezione architetturale | Approvato |
| CV-005 | Le app **DEVONO** usare l'italiano (`it`) come lingua sorgente iniziale mediante un catalogo di stringhe condiviso. | ADR-0004 | Ispezione build e TV-014 | Approvato |
| CV-006 | GlifiCore **DEVE** usare l'italiano (`it`) come lingua analitica predefinita soltanto quando il progetto non ne specifica una. | ADR-0004 | Test di configurazione | Approvato |
| CV-007 | Ogni testo dell'interfaccia **DEVE** essere associato a una chiave semantica in un catalogo condiviso internazionalizzabile. | ADR-0005 | TV-015 | Approvato |
| CV-008 | La lingua dell'interfaccia **NON DEVE** determinare la lingua usata per analizzare un corpus. | ADR-0005 | Test di configurazioni incrociate | Approvato |
| CV-009 | L'app macOS **DEVE** usare App Sandbox con accesso in lettura/scrittura ai soli file selezionati dall'utente, salvo capability approvate successivamente. | ADR-0006 | TV-016 | Approvato |
| CV-010 | Ogni app **DEVE** includere un privacy manifest coerente con dati raccolti, tracking e required-reason API effettivamente usati. | ADR-0006 | TV-016 | Approvato |
| CV-011 | Lo stato mutabile di presentazione **DEVE** essere isolato sul Main Actor; operazioni lunghe e di dominio **NON DEVONO** risiedere nelle view. | ADR-0006 | Ispezione architetturale e TV-018 | Approvato |
| CV-012 | Capability, entitlement e usage description **NON DEVONO** essere aggiunti prima del requisito funzionale che li rende necessari. | ADR-0006 | TV-016 | Approvato |
| CV-013 | Le capacità di CPU, GPU, Neural Engine, memoria e modelli di sistema **DEVONO** essere interrogate tramite API di piattaforma; il comportamento non deve dipendere dal nome commerciale del chip. | ADR-0008 | TV-019, TV-020 | Approvato |
| CV-014 | Foundation Models e altri modelli generativi **NON DEVONO** essere necessari per apertura, ricerca, conteggi e riproduzione delle analisi fondamentali. | ADR-0008 | TV-020 | Approvato |
| CV-015 | Framework di sistema Apple appropriati **DEVONO** essere valutati prima di introdurre una dipendenza esterna o un'implementazione proprietaria equivalente. | ADR-0008; GS-STD-001-13 | Revisione architetturale | Approvato |
| CV-016 | Ogni backend accelerato **DEVE** restare dietro un contratto sostituibile di GlifiCore e avere un percorso di riferimento verificabile. | ADR-0008 | TV-008, TV-019 | Approvato |
| CV-017 | Il primo canale di distribuzione **DEVE** essere App Store non in elenco dopo la normale App Review. | ADR-0011 | TV-025 | Approvato |
| CV-018 | Le app macOS e iPadOS **DEVONO** condividere bundle identifier, versione commerciale e numero di build nella singola identità App Store multipiattaforma. | ADR-0011 | TV-022 | Approvato |
| CV-019 | La build Mac App Store **DEVE** mantenere App Sandbox; ogni build **DEVE** includere icona valida, privacy manifest e dichiarazione export compliance riesaminata. | ADR-0006, ADR-0011 | TV-016, TV-022, TV-023 | Approvato |

## 8. Esclusioni correnti

Non sono requisiti correnti:

- supporto di piattaforme non Apple;
- modifica delle fonti come in un editor generalista;
- dipendenza obbligatoria da un singolo database;
- dipendenza esclusiva da Metal, Core ML, Neural Engine o Apple Intelligence per i flussi fondamentali;
- servizi cloud o sincronizzazione, finché non esiste una decisione esplicita.

## 9. Verifica, validazione e tracciabilità

I metodi e le evidenze pianificate sono definiti nella [Matrice di tracciabilità](tracciabilita.md). La specifica nel suo insieme non è ancora una baseline approvata perché manca la validazione con stakeholder reali. Le singole decisioni già approvate conservano tuttavia lo stato indicato nelle rispettive righe.

## 10. Questioni bloccanti per la baseline

- priorità e perimetro MVP;
- codifiche e formati strutturati supportati;
- lingue successive all'italiano e soglie di qualità linguistica;
- modello canonico degli offset;
- serializzazione, digest, persistenza e migrazione concrete per descriptor e Analysis DAG;
- sintassi e semantica delle query;
- soglie UX, profili degli utenti, compiti e campione di validazione;
- serializzazione di indagini, storia ramificata, piani, findings e relazioni;
- policy MVP del planner e regole di solidità per ciascuna famiglia;
- sottoinsieme di metodi analitici per l'MVP, dataset di riferimento e tolleranze numeriche;
- corpus, hardware e soglie prestazionali;
- funzioni assistive che possono usare Foundation Models e relativa policy di modello, contesto e retention;
- modello di accesso per il pubblico della distribuzione non in elenco.

Questi temi sono registrati in [Decisioni aperte](decisioni-aperte.md).
