# Glossario

| Campo | Valore |
| --- | --- |
| Identificatore | GS-GLO-001 |
| Tipo | Glossario e definizioni |
| Versione | 0.5.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

| Termine | Definizione nel progetto |
| --- | --- |
| Analysis DAG | Grafo aciclico diretto i cui nodi sono artefatti o trasformazioni analitiche e i cui archi rappresentano dipendenze semantiche usate per lineage, riuso e invalidazione. |
| AnalysisDescriptor | Contratto persistibile che identifica dati, algoritmo, versione, preprocessing, rappresentazione, parametri, seed, backend, precisione, software e dipendenze di un'analisi. |
| Artefatto derivato | Dato prodotto da una trasformazione identificabile di una fonte o di un altro artefatto, per esempio testo normalizzato, token, indice o risultato analitico. |
| Baseline | Versione formalmente approvata e identificata di un information item o altro elemento di configurazione. |
| Baseline candidata | Contenuto proposto per l'approvazione che non costituisce ancora una baseline. |
| Concern | Interesse o problema rilevante per uno o più stakeholder rispetto al sistema. |
| Collocazione | Coppia o configurazione co-occorrente valutata mediante una misura di associazione esplicita. |
| Co-occorrenza | Osservazione congiunta di unità entro un contesto dichiarato, per esempio frase o finestra. |
| Corpus | Vista logica su un insieme di documenti o porzioni di documento, eventualmente definita tramite metadati. |
| Deroga | Autorizzazione temporanea e controllata a non applicare una regola dello standard entro un ambito definito. |
| Documento | Entità persistente con identità stabile che rappresenta una fonte e le sue informazioni descrittive. |
| Effect size | Misura della grandezza o forza di un effetto, distinta dalla significatività statistica. |
| Frequency spectrum | Distribuzione `V_r` del numero di type osservati esattamente `r` volte. |
| Fonte | Contenuto originale acquisito dal sistema e non modificato implicitamente dalle trasformazioni analitiche. |
| Glifi Studio | Nome canonico e localizzato del prodotto; non coincide con i suoi identificatori tecnici senza spazi. |
| GlifiStudio | Radice tecnica usata da workspace, progetto, target e tipi applicativi. |
| Information item | Insieme identificabile di informazioni prodotto o mantenuto durante il ciclo di vita; in questo progetto è normalmente registrato in uno o più file Markdown. |
| Gate | Punto di controllo del ciclo di vita nel quale evidenze definite vengono valutate prima di autorizzare il passaggio successivo. |
| Keyness | Famiglia di confronti che quantifica quanto un termine caratterizza un gruppo target rispetto a un riferimento, conservando test, direzione ed effect size. |
| Lineage | Catena tracciabile che collega un artefatto alle fonti, alle trasformazioni, alle versioni e ai parametri che lo hanno prodotto. |
| Licenza software | Insieme di condizioni con cui il titolare autorizza uso, modifica e distribuzione del software o di altro materiale. |
| Model | Rappresentazione costruita secondo le convenzioni di un viewpoint per rispondere a specifici concern. |
| Modello empirico | Relazione matematica stimata su osservazioni, con procedura di fitting e bontà dell'adattamento; non è una proprietà esatta del corpus. |
| Metadata-first | Principio per cui i metadati tipizzati sono dimensioni e variabili dell'analisi, non soltanto filtri o testo descrittivo. |
| Non conformità | Mancato rispetto di un requisito, una regola o un criterio applicabile e privo di deroga valida. |
| Progetto Glifi Studio | Unità di lavoro persistente contenente fonti o riferimenti, metadati, corpus, configurazioni, artefatti e risultati. |
| Requisito | Obbligazione o vincolo necessario, espresso in forma precisa e verificabile, relativo al sistema di interesse. |
| Quality gate | Insieme di controlli obbligatori il cui esito determina se una modifica o un rilascio può procedere. |
| Significatività statistica | Valutazione di compatibilità dei dati con un'ipotesi secondo un test dichiarato; non misura la grandezza dell'effetto né la probabilità che l'ipotesi sia vera. |
| Stakeholder | Individuo, gruppo o organizzazione con un interesse rilevante nel sistema. |
| Token | Occorrenza prodotta da una tokenizzazione versionata e collegata a una posizione del testo/fonte. |
| Type | Valore lessicale distinto ottenuto mappando token secondo forma, lemma o altra chiave dichiarata. |
| Unità analitica | Entità identificata su cui si aggregano osservazioni, per esempio documento, segmento, autore, categoria o periodo. |
| Matrice unità-termine | Matrice sparsa o logica in cui righe identificate sono unità analitiche, colonne identificate sono type e celle sono conteggi o trasformazioni dichiarate. |
| Variante algoritmica | Formula e procedura versionate che eliminano ambiguità fra implementazioni accomunate da un nome generico. |
| View | Insieme di uno o più model che esprime l'architettura rispetto a specifici concern. |
| Viewpoint | Convenzioni che stabiliscono come costruire, interpretare e usare una view per determinati stakeholder e concern. |

## Abbreviazioni

| Sigla | Significato |
| --- | --- |
| ADR | Architecture Decision Record |
| CA | Correspondence Analysis |
| CLI | Command-line interface |
| DAG | Directed Acyclic Graph |
| FDR | False Discovery Rate |
| KWIC | Key Word In Context |
| LDA | Latent Dirichlet Allocation |
| LSA | Latent Semantic Analysis |
| NMF | Non-negative Matrix Factorization |
| OCR | Optical Character Recognition |
| PCA | Principal Component Analysis |
| PRNG | Pseudo-Random Number Generator |
| SRS | Software Requirements Specification |
| SPDX | Software Package Data Exchange; in questo progetto fornisce l'identificatore standard della licenza. |
| SVD | Singular Value Decomposition |
| TF-IDF | Term Frequency–Inverse Document Frequency |
