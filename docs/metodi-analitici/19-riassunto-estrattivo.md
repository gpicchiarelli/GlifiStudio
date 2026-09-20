<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Riassunto estrattivo deterministico

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-19 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Architettura approvata; algoritmi MVP da selezionare |
| Documento padre | [GS-MET-001](README.md) |

## Contratto

Il riassunto estrattivo seleziona frasi esistenti senza generarne il testo. Input,
segmenter, unità, budget (frasi, token o caratteri), scoring, ridondanza, tie-break e
ordine di presentazione **DEVONO** essere espliciti. Ogni frase selezionata conserva
`SentenceID`, score, rank e posizione sorgente.

Un summarizer dichiarato D0/D1 **DEVE** restituire la stessa selezione a parità di
input, descrittore e versione. L'ordine di output predefinito è quello della fonte;
l'ordine per score è una vista separata.

## Famiglie candidate

- `SentenceTFIDFMean-v1`: media dei pesi TF-IDF dei token inclusi della frase, con
  weighting GS-MET-001-07 e zero per frase senza token; tie-break sulla posizione.
- `CentroidCosine-v1`: centroide come media dei vettori delle unità, rilevanza della
  frase come coseno col centroide; vettori nulli sono esclusi con diagnostica.
- `TextRankSentence-v1`: nodi-frase, archi pesati dalla similarità dichiarata e
  PageRank con damping, soglia, dangling policy, tolleranza e iterazioni persistiti.
- `LexRankSentence-v1`: grafo di similarità coseno tra frasi, continuo o con soglia
  come variante esplicita, seguito dalla centralità versionata.
- `MMR-v1`: seleziona iterativamente
  `argmax_s [λ rel(s) - (1-λ) max_{u∈S} sim(s,u)]`, con `0≤λ≤1`, funzioni `rel` e
  `sim`, stato iniziale e tie-break dichiarati.

L'inclusione in questa specifica non rende tutte le famiglie obbligatorie nel primo
rilascio. Un'implementazione diventa disponibile soltanto dopo avere fissato
completamente la variante, superato fixture di riferimento e registrato i limiti
linguistici.

## Separazione dalla generazione

Foundation Models o altri modelli che producono nuovo testo appartengono alla
categoria generativa N1. Il loro output **DEVE** essere marcato non autoritativo e
conservare modello disponibile, versione logica, configurazione, istruzioni,
contesto, strumenti, timestamp e provenienza. Un riassunto generativo **NON DEVE**
sostituire o essere esportato come riassunto estrattivo.

## Valutazione

I test verificano budget, tie, frasi duplicate, input vuoto, source order, offset e
ripetibilità. ROUGE o valutazioni umane, se adottate, richiedono tokenizzazione,
variante, riferimenti e protocollo propri; non provano da sole correttezza fattuale.

## Riferimenti scientifici

- Mihalcea e Tarau, [TextRank](https://aclanthology.org/W04-3252/), 2004.
- Erkan e Radev, [LexRank](https://doi.org/10.1613/jair.1523), 2004.
- Carbonell e Goldstein, [Maximal Marginal Relevance](https://doi.org/10.1145/290941.291025), 1998.
