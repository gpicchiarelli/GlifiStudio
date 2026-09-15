<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Valutazione dei servizi linguistici

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-18 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Italiano come baseline; soglie da approvare |
| Documento padre | [GS-MET-001](README.md) |

## Contratto del servizio

Tokenizzazione, sentence segmentation, lemmatizzazione, POS tagging, morphological
features, named entity recognition e futura analisi sintattica **DEVONO** essere
servizi sostituibili. Ogni output conserva lingua, locale quando rilevante, schema di
tag, backend, versione del backend/modello, versione OS, configurazione e offset
verso la fonte.

La disponibilità di Apple Natural Language o di un modello Core ML **NON È**
evidenza di correttezza. L'italiano è la baseline iniziale; aggiungere una lingua
richiede un profilo di valutazione proprio e non modifica gli artefatti italiani già
versionati.

## Corpus di riferimento

Ogni valutazione **DEVE** dichiarare:

- corpus, versione, checksum, licenza e modalità di acquisizione;
- lingua, varietà, dominio, genere, epoca e criteri di campionamento;
- linee guida e schema delle annotazioni gold;
- split train/dev/test senza contaminazione nota;
- unità di valutazione, esclusioni e gestione dei casi ambigui;
- backend e ambiente esatti.

Corpora reali con restrizioni **NON DEVONO** essere inclusi nel repository; possono
essere riferiti tramite manifest riproducibile e checksum.

## Metriche

Con `TP`, `FP`, `FN`:

```text
precision = TP/(TP+FP)
recall    = TP/(TP+FN)
F1        = 2PR/(P+R)
accuracy  = corretti/totale
```

Denominatori nulli seguono una policy dichiarata e non diventano automaticamente
uno. Micro, macro e weighted average sono risultati distinti.

| Servizio | Valutazione minima |
| --- | --- |
| Tokenizzazione/segmentazione | precision, recall e F1 dei confini; exact match delle unità |
| Lemmatizzazione | accuracy esatta per token gold; errori per forma/POS |
| POS | accuracy e F1 per classe, matrice di confusione |
| Feature morfologiche | exact-set accuracy e P/R/F1 per attributo |
| NER | P/R/F1 span-level exact e, separatamente, tipo corretto |
| Sintassi futura | metrica dipendente dallo schema, per esempio UAS/LAS, specificata prima dell'uso |

Il matching parziale di span **DEVE** avere variante separata. Intervalli di
confidenza, se prodotti, dichiarano metodo e unità di resampling.

## Gate e deriva

Soglie per lingua, servizio, dominio e release sono approvate tramite DA-008. Un
backend può essere promosso soltanto se supera dataset gold, casi avversi, round-trip
degli offset e test di stabilità. Aggiornamenti di macOS/iPadOS o del modello
richiedono una nuova valutazione di deriva; regressioni oltre soglia impediscono il
riuso trasparente della vecchia versione logica.

## Verifica italiana iniziale

Le fixture devono includere apostrofi ed elisioni, clitici, parole composte,
abbreviazioni, numeri e date italiane, punteggiatura, virgolette, Unicode composto,
nomi propri e code-switching. Le fixture sintetiche verificano contratti e offset;
non sostituiscono un corpus gold rappresentativo.
