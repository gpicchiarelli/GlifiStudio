<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Contratto dell'analisi e provenienza

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-01 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.2.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline da revisionare |
| Documento padre | [GS-MET-001](README.md) |

## AnalysisDescriptor concettuale

Ogni artefatto analitico persistibile **DEVE** essere accompagnato da un descrittore
semanticamente completo. Il contratto precede qualsiasi tipo Swift definitivo e
comprende almeno:

| Gruppo | Campi obbligatori |
| --- | --- |
| Identità | `analysisID`, tipo di artefatto, algoritmo, versione logica |
| Dati | `corpusID`, versione immutabile del corpus, selezione e unità analitica |
| Testo | catena di preprocessing, vocabolario, stopword, configurazione linguistica e versioni |
| Rappresentazione | schema, orientamento, weighting, normalizzazione, sparsità e trattamento dei mancanti |
| Esecuzione | parametri risolti, seed, backend, precisione numerica, tolleranze e classe di determinismo |
| Software | versione di Glifi Studio/GlifiCore e versione di formato del descrittore |
| Dipendenze | identità e digest semantico di ogni nodo genitore del DAG |
| Esito | stato, diagnostica, avvisi, conteggi esclusi e motivi di esclusione |

I valori predefiniti **DEVONO** essere risolti e persistiti come valori effettivi; non
è sufficiente conservare “default”. Ordine delle categorie, convenzione dei
logaritmi, algoritmo pseudo-casuale e politica dei valori nulli **DEVONO** essere
espliciti quando influenzano l'esito.

## Classificazione epistemica

Ogni campo del risultato **DEVE** appartenere a una delle categorie:

- `osservato`: conteggio o valore letto dalle fonti;
- `trasformato`: funzione deterministica dichiarata di dati osservati;
- `stimato`: parametro ottenuto tramite fitting o campionamento;
- `inferito`: statistica inferenziale con ipotesi e incertezza;
- `annotato`: giudizio umano o servizio linguistico con autore/backend;
- `interpretato`: proposizione prodotta deterministicamente da evidenze mediante
  un rule set identificato e versionato;
- `generativo`: output probabilistico non autoritativo.

La classificazione **NON DEVE** essere persa in esportazione o visualizzazione.

## Lineage analitico

Il lineage è un grafo risolvibile, non una nota testuale. Quando il metodo lo
consente, ogni valore aggregato **DEVE** esporre riferimenti compatti alle unità,
occorrenze o celle che vi contribuiscono. Il sistema **DEVE** poter navigare:

```text
risultato ↔ cella/elemento ↔ unità analitica ↔ segmento/token ↔ fonte e posizione
```

Una matrice o un modello può usare lineage materializzato, indici invertiti o una
query riproducibile; la strategia è sostituibile, ma il riferimento **DEVE** restare
valido per la versione del corpus dichiarata.

Ogni valore interrogabile dichiara una classe:

- `exact`: insieme completo e risolvibile delle osservazioni determinanti;
- `contributive`: contributori e pesi o ruoli pertinenti senza inversione uno-a-uno;
- `derivational`: input e procedura esatti di una trasformazione non invertibile.

Top-k, campioni, documenti rappresentativi o nearest neighbor **NON DEVONO** essere
presentati come lineage `exact`. Aggregazioni massive possono fornire una query o
un campione dichiarato con copertura, criterio e ordinamento espliciti.

## Identità e serializzazione

Il descrittore **DEVE** avere una serializzazione canonica, indipendente dall'ordine
accidentale di mappe o task concorrenti. Il digest semantico **DEVE** includere tutti
i campi capaci di cambiare il risultato e **NON DEVE** includere etichette puramente
presentazionali. Collisioni, versioni sconosciute e dipendenze non risolvibili
**DEVONO** essere errori espliciti.

## Criteri di verifica

- round-trip del descrittore senza perdita semantica;
- modifica di ogni parametro significativo con conseguente cambio d'identità;
- invariabilità dell'identità rispetto a titolo, posizione UI e ordine di
  serializzazione non semantico;
- navigazione campionata dal risultato alla fonte corretta;
- classificazione exact/contributive/derivational e rifiuto dei falsi exact;
- rifiuto di descrittori incompleti, versioni ignote e dipendenze incoerenti.

## Profilo implementato `studio.glifi.analysis-descriptor.v1`

GlifiCore espone un primo descrittore `Codable`, immutabile e `Sendable` che
risolve esplicitamente algoritmo/versione, corpus/versione, selezione, unità,
preprocessing, profili linguistici, rappresentazione, parametri, seed, backend,
policy numerica, classe D0/D1/P1/N1, schema di output, software e dipendenze.

I parametri usano un'algebra tagged priva di ambiguità tra booleani, interi,
binary64, testo, liste e oggetti. Float non finiti sono rifiutati, signed zero e
Unicode sono canonicalizzati, le chiavi collidenti dopo NFC falliscono e il JSON
usa chiavi ordinate. Il digest completo e `AnalysisNodeID` SHA-256 usano domain
separation; decodifica, versione e identità sono rivalidate fail-closed.

Il profilo costituisce la fondazione logica: non rende ancora persistenti
descriptor e Artifact nel package `.glifi` e non implementa lineage a livello di
cella o valore.
