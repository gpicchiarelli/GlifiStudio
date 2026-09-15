# Visione e principi

| Campo | Valore |
| --- | --- |
| Identificatore | GS-VIS-001 |
| Tipo | Visione, contesto e stakeholder needs |
| Versione | 0.5.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Riferimento | ISO/IEC/IEEE 29148:2018, profilo tailored |

## Visione

Glifi Studio è un ambiente computazionale professionale Apple-native per
acquisizione, organizzazione, interrogazione, analisi quantitativa e qualitativa,
corpus analysis, linguistica computazionale, text mining, content analysis e studio
statistico e semantico di documenti e grandi collezioni testuali su macOS e iPadOS.

Il sistema accompagna l'utente lungo l'intera catena di lavoro:

> acquisizione → estrazione → normalizzazione → segmentazione → tokenizzazione → annotazione → indicizzazione → analisi → esplorazione dei risultati

Non è un editor arricchito con alcune funzioni statistiche, una semplice utility per
contare parole o un insieme eterogeneo di strumenti. È un sistema scientificamente
fondato nel quale dati, trasformazioni, algoritmi e risultati hanno semantica
esplicita, provenienza verificabile, comportamento riproducibile e implementazioni
validabili indipendentemente dalla GUI e dal backend computazionale.

## Ambiti d'uso

Il dominio comprende:

- linguistica computazionale e corpus analysis;
- text mining e content analysis;
- ricerca documentale;
- analisi quantitativa, statistica e semantica del testo;
- analisi comparativa di sottoinsiemi definiti tramite metadati.

## Stakeholder candidati

Gli stakeholder devono essere validati prima dell'approvazione della baseline.

| ID | Stakeholder | Interesse principale |
| --- | --- | --- |
| ST-01 | Ricercatore o analista testuale | Correttezza, capacità analitiche, verificabilità e riproducibilità |
| ST-02 | Utente professionale macOS o iPadOS | Flusso di lavoro, reattività, gestione dei progetti e navigazione alle fonti |
| ST-03 | Sviluppatore di Glifi Studio | Contratti chiari, modularità, testabilità e osservabilità |
| ST-04 | Manutentore o responsabile del rilascio | Evolvibilità, migrazioni, compatibilità e diagnosi |
| ST-05 | Responsabile qualità | Requisiti verificabili, tracciabilità, benchmark e prove di riferimento |
| ST-06 | Responsabile dei dati | Integrità delle fonti, provenienza, privacy e gestione del ciclo di vita |

## Necessità degli stakeholder

| ID | Necessità | Fonte | Stato |
| --- | --- | --- | --- |
| NS-001 | Analizzare in modo interattivo e sistematico singoli documenti e grandi corpus. | Appunti 1 e 2 | Baseline candidata |
| NS-002 | Verificare ogni risultato nel contesto della fonte originaria. | Appunti 1 e 2 | Baseline candidata |
| NS-003 | Elaborare collezioni più grandi della memoria disponibile. | Appunti 1 e 2 | Baseline candidata |
| NS-004 | Chiudere e riaprire un progetto senza perdere stato o ripetere calcoli validi. | Appunti 1 | Baseline candidata |
| NS-005 | Creare e confrontare corpus o sottoinsiemi mediante metadati. | Appunti 1 | Baseline candidata |
| NS-006 | Automatizzare elaborazioni e usare il motore senza interfaccia grafica. | Appunti 1 e 2 | Baseline candidata |
| NS-007 | Ottenere risultati corretti, riproducibili e misurabili. | Appunti 1 e 2 | Baseline candidata |
| NS-008 | Usare un'esperienza nativa e performante su macOS e iPadOS. | Appunti 1 e 2; decisione del 2026-09-15 | Approvata |
| NS-009 | Comprendere esattamente significato, ipotesi, parametri, incertezza e limiti di ogni risultato analitico. | Direzione scientifica del 2026-09-15 | Approvata |
| NS-010 | Usare metadati e tempo come dimensioni native per raggruppare, confrontare e spiegare corpus e sottocorpus. | Direzione scientifica del 2026-09-15 | Approvata |
| NS-011 | Esplorare relazioni lessicali e strutture multivariate mediante matrici, distanze, fattori, cluster e reti senza perdere il collegamento alle fonti. | Direzione scientifica del 2026-09-15 | Approvata |
| NS-012 | Eseguire content analysis manuale e qualitativa con codebook, annotazioni e affidabilità fra codificatori tracciabili. | Direzione scientifica del 2026-09-15 | Approvata |
| NS-013 | Conoscere la qualità osservata dei servizi linguistici sulla lingua e sul dominio applicabili. | Direzione scientifica del 2026-09-15 | Approvata |
| NS-014 | Disporre di percorsi classici riproducibili per sintesi e topic analysis distinti dall'intelligenza generativa. | Direzione scientifica del 2026-09-15 | Approvata |

La derivazione di queste necessità verso i requisiti software è registrata nella [Matrice di tracciabilità](tracciabilita.md).

## Unità di lavoro

L'unità primaria per l'utente è il **progetto Glifi Studio**, non il singolo file. Un progetto persistente raccoglie:

- riferimenti alle fonti originali;
- metadati e corpus logici;
- configurazioni linguistiche e trasformazioni;
- indici e artefatti derivati;
- analisi, parametri e risultati.

La chiusura e la riapertura del progetto non devono comportare la perdita dello stato né la ripetizione non necessaria di elaborazioni costose.

## Principi costituzionali

### Correttezza

La correttezza semantica, documentale e numerica ha priorità. Ogni rappresentazione deve avere un significato definito e ogni trasformazione deve rendere riconoscibili input, output e proprietà preservate.

### Provenienza e riproducibilità

La provenienza è parte del dato. Ogni risultato deve poter essere ricondotto alla versione del corpus, alla sorgente, alle trasformazioni e ai parametri che lo hanno prodotto.

### Semantica scientifica

Ogni metodo deve dichiarare variante matematica, dominio, precondizioni, casi
degeneri, classe di determinismo e criteri di verifica. Osservazione, modello,
fitting, inferenza, effect size e generazione sono categorie distinte.

### Metadata-first

I metadati sono variabili analitiche tipizzate, non semplici etichette di filtro.
Possono determinare selezioni, raggruppamenti, confronti, assi e viste temporali
soltanto preservandone semantica, provenienza e valori mancanti.

### Scalabilità

La dimensione del corpus può modificare il costo computazionale, non il modello concettuale del sistema. Nessun algoritmo fondamentale deve richiedere che l'intero corpus risieda simultaneamente in memoria.

### Prestazioni misurabili

Le prestazioni sono una proprietà architetturale. Le ottimizzazioni non banali devono essere giustificate tramite misure riproducibili di throughput, latenza, memoria e I/O.

### Separazione delle responsabilità

Il motore, la persistenza e la presentazione sono distinti. La logica scientifica non appartiene alla GUI e i risultati analitici non devono essere modellati in funzione della loro visualizzazione.

### Evolvibilità

Algoritmi, formati, framework e capacità analitiche potranno cambiare. Contratti piccoli, dipendenze acicliche e implementazioni sostituibili devono rendere possibile questa evoluzione senza riscritture periodiche.

## Non-obiettivi architetturali

Glifi Studio non viene progettato come:

- applicazione per piattaforme non Apple a costo di rinunciare alle capacità native di macOS e iPadOS;
- editor di testo generalista;
- contenitore in cui un unico database determina il modello del dominio;
- sistema che materializza sempre documenti o corpus interi in una `String`;
- applicazione in cui GPU, machine learning o parallelismo sono introdotti senza un beneficio misurato.

## Assunzioni e dipendenze

- L'italiano è la lingua iniziale dell'interfaccia e dell'analisi; lingue successive e soglie qualitative restano da definire.
- La disponibilità di framework Apple non implica automaticamente che essi soddisfino i requisiti scientifici.
- L'elaborazione è concepita come locale; le garanzie formali di privacy e l'eventuale uso di servizi remoti restano da decidere.
- L'uso commerciale del nome richiede una verifica giuridica separata.

## Famiglia del prodotto

- **Glifi Studio**: applicazioni interattive native per macOS e iPadOS.
- **GlifiCore**: motore computazionale.
- **GlifiKit**: contratto/API stabile verso il motore.
- **GlifiCLI**: accesso headless, batch e automazione.
- **GlifiStore**: progetto esistente da valutare tecnicamente, senza integrazione automatica basata sul solo nome.
