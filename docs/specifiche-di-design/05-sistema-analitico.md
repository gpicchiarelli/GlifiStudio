<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Sistema analitico

| Campo | Valore |
| --- | --- |
| Identificatore | GS-ANA-001 |
| Tipo | Specifica di design del sistema analitico |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline proposta; policy e regole MVP da convalidare |
| Riferimenti | GS-MET-001; GS-UX-001-03–08; GS-DOM-001; GS-DAT-001; ADR-0013; ADR-0016 |

## Scopo e separazione

Questa specifica governa capability, planner, identità del DAG, invalidazione,
esecuzione logica, trasformazione di Artifact in Evidence/Finding/Caveat, ranking
editoriale e spiegazione. GS-MET resta l'autorità su formule e precondizioni;
GS-RUN governa task, memoria e scheduling fisico.

```text
Question + AnalyticalIntent + CorpusVersion + CollectionProfile
                       ↓
               Analysis Planner
                       ↓
       AnalysisPlanRevision / Analysis DAG
                       ↓
        Artifact → Evidence → Finding + Caveat
                       ↓
          ranking editoriale → spiegazione
```

## Capability e applicabilità

Ogni capacità pubblica fornisce un `CapabilityDescriptor` versionato con:

- ID semantico, famiglia, contratto GS-MET e versioni implementate;
- tipi degli input/output, parametri, default e vincoli;
- precondizioni dure, segnali di qualità e motivi di non applicabilità;
- cost model parametrico, strategie streaming/sparse e backend equivalenti;
- classe di determinismo, tolleranze, seed e policy numerica;
- requisiti linguistici, metadati, lineage e visualizzazioni compatibili.

L'applicabilità è `applicable`, `applicableWithCaveats`, `notApplicable` o
`unknown`. Solo i primi due possono entrare nel piano; `unknown` non equivale a
“probabilmente sì”. Motivi ed esclusioni sono persistiti e spiegabili.

## Planner deterministico

Input uguali, catalogo di capability uguale e policy uguale producono lo stesso
piano canonico. Il planner:

1. risolve l'intenzione e gli slot senza rinominare i metodi;
2. interroga CollectionProfile e capability;
3. costruisce candidati e dipendenze;
4. elimina non applicabili e ridondanti con regole versionate;
5. stima costo e applica il budget;
6. ordina con tie-break stabile;
7. registra inclusioni, esclusioni, fallback e domande irrisolte.

La baseline `planner-mvp-v1` ammette soltanto capacità GS-PROD-001. Nessun comando
“Analizza tutto” aggira il budget o promuove automaticamente metodi sperimentali.

## Identità semantica dei nodi

`AnalysisNodeID` è SHA-256 con domain separation di una serializzazione canonica:

```text
glifi.analysis-node.v1 ||
method-id || method-version || input-artifact-digests ||
resolved-parameters || linguistic-profile-versions ||
numeric-policy || seed-policy || output-schema-version
```

Tempo di esecuzione, progresso, UI e percorso temporaneo non entrano nell'identità.
Un backend può essere escluso soltanto se il relativo contratto prova equivalenza
semantica entro tolleranza; altrimenti backend e versione entrano nell'identità.
L'`ExecutionRecord` conserva comunque host class, backend, tempi, risorse e software.

Parametri impliciti sono vietati al momento del commit del piano. Mappe e insiemi
sono ordinati canonicamente; float, NaN, infinito e signed zero usano la codifica
GS-MET/GS-DAT, non la descrizione locale.

## Analysis DAG e riuso

Il grafo è diretto, aciclico e tipizzato. Ogni arco dichiara porta di output/input
e vincolo di schema. Prima del commit si validano cicli, input mancanti, versioni,
applicabilità e budget. Nodi semanticamente identici sono deduplicati nello stesso
progetto e possono condividere Artifact immutabili.

Un Artifact è riusabile se digest, schema, descriptor e tutti gli input sono
validi. Una modifica invalida transitivamente i discendenti effettivi, non i
fratelli. Il grafo conserva stato `valid`, `stale`, `missing`, `running`, `failed`
o `cancelled`; `stale` non viene mostrato come risultato corrente.

Materializzazione e lazy evaluation sono proprietà del piano. Checkpoint includono
ID nodo, partizione, schema, input digest e checksum; una partizione incompatibile
è scartata. Il garbage collector usa raggiungibilità da piani, report e storia.

## Motore interpretativo

Una `InterpretationRule` versionata dichiara famiglia, pattern di Artifact,
precondizioni, trasformazione in Evidence, condizioni di Finding, Caveat e chiavi
localizzabili. A parità di input produce lo stesso risultato e lo stesso ordine.

La regola conserva:

- osservazioni e statistiche effettivamente usate;
- soglie, effect size e correzioni multiple applicabili;
- evidenze favorevoli, contrarie e non disponibili;
- motivi di soppressione, deduplicazione o `insufficientEvidence`;
- grado di supporto secondo una `SupportPolicy` specifica della famiglia.

Non esiste un confidence score universale. Probabilità, p-value, qualità di
rappresentazione, stabilità e copertura non sono convertiti in una percentuale
intercambiabile.

## Ranking editoriale

Il ranking opera dopo un gate di eleggibilità: lineage completo, precondizioni
soddisfatte, supporto minimo della famiglia e assenza di corruzione. Risultati di
famiglie epistemicamente non comparabili non ricevono un singolo punteggio globale.

`editorial-rank-v1` usa confronto lessicografico o fronte di Pareto entro lo stesso
intento e famiglia:

1. rilevanza dichiarata per l'intento;
2. classe di supporto specifica della famiglia;
3. effect size o magnitudine appropriata;
4. copertura e qualità dei dati;
5. stabilità a perturbazioni definite;
6. novità rispetto ai findings già selezionati;
7. non ridondanza e completezza del lineage;
8. FindingID come tie-break.

Le regole di diversificazione tra famiglie sono quote editoriali versionate, non
un confronto numerico fittizio. Una persona può riordinare o includere risultati;
questa scelta entra nella storia e non modifica il supporto scientifico.

## Contratto di spiegazione

Ogni Finding risponde a “Perché lo dici?” con una struttura, non testo libero:

```text
conclusione
├── Evidence usate e relativo supporto
├── osservazioni/fonti navigabili
├── metodo, variante, parametri e limiti
├── alternative considerate o escluse con motivo
└── Caveat, dati mancanti e condizioni di validità
```

La versione compatta e quella tecnica derivano dallo stesso `ExplanationModel`.
Una spiegazione incompleta impedisce la promozione del Finding a report. Un testo
generativo può parafrasare soltanto dopo il modello strutturato e resta marcato non
autoritativo.

## API e stati operativi

GlifiCore espone pianificazione ed esecuzione come operazioni asincrone cancellabili.
GlifiKit e GlifiCLI usano gli stessi `AnalysisPlanRevision`, `QueryAST`, Artifact ed
errori tipizzati. Un errore di un ramo non annulla artefatti validi indipendenti;
lo stato del piano rende visibili completezza e partial failure.

### Slice implementata `corpus-profile-it-v1`

La prima slice eseguibile acquisisce una generazione verificata, ordina le
`SourceRevisionID` canonicamente e calcola in memoria entro limiti espliciti:

- `D`, caratteri come extended grapheme cluster, frasi, `N`, `V`, frequenze
  assolute/relative, document frequency e range;
- `TTR-v1`, `MSTTR-v1` con `discard-remainder` e `MATTR-v1` sulla concatenazione
  canonica delle revisioni, con finestra dichiarata;
- n-grammi di parole che non attraversano il confine del documento e
  `GriesDP-v1` sulla partizione per revisione;
- matrice documento-termine sparsa con righe `SourceRevisionID`, colonne
  lessicografiche, `TF-raw-v1`, `IDF-smooth-v1` e `TFIDF-v1`.

L'identità `corpus-profile-it-v1` e il digest SHA-256 includono revisione,
contenuto, contratto di estrazione e parametri analitici. I limiti predefiniti sono
1.000 documenti, 256 MiB sorgente complessivi, 100.000 type, 100.000 n-grammi
distinti e 500.000 celle non-zero. Cancellazione e superamento dei limiti producono
failure tipizzate senza modificare la generazione.

Questa slice è un risultato effimero di riferimento: non implementa ancora
segmenti documentali, spill fuori memoria, AnalysisDescriptor/AnalysisNodeID,
DAG, persistenza/deduplica degli Artifact, keyness, analisi temporale,
Evidence/Finding/Caveat o planner. Non può quindi essere promossa a conformità
completa GS-ANA-001 né al percorso Must 0.1.

## Conformità

- golden decision table del planner e motivi di esclusione;
- test DAG per cicli, deduplica, invalidazione transitiva e riuso selettivo;
- round-trip dell'identità semantica attraverso processi e scheduling differenti;
- golden test di InterpretationRule, Caveat propagation e explanation contract;
- test metamorfici del ranking e assenza di score universale;
- equivalenza osservabile tra GUI, GlifiKit e GlifiCLI.
