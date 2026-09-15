<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Progressive disclosure e solidità dei risultati

| Campo | Valore |
| --- | --- |
| Identificatore | GS-UX-001-06 |
| Tipo | Specifica normativa dell'esperienza utente |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Principio approvato; soglie per famiglia da decidere |
| Documento padre | [GS-UX-001](README.md) |

## Un'unica esperienza a profondità crescente

Glifi Studio **NON DEVE** separare una modalità “semplice” e una “esperta” che
possano produrre significati diversi. Esiste una sola esperienza con quattro
livelli collegati:

1. **Conclusione** — che cosa è emerso, in linguaggio comprensibile;
2. **Evidenza** — quantità, confronto, incertezza, solidità e caveat;
3. **Fonti** — documenti, segmenti, occorrenze o contributori applicabili;
4. **Metodo** — variante, parametri, preprocessing, algoritmo, test, correzioni,
   backend, versione e riproducibilità.

La catena `Conclusione → Evidenza → Fonti → Metodo` **DEVE** essere raggiungibile
anche da tastiera e tecnologie assistive, preservando selezione e contesto. Nessun
livello può contraddire o sostituire quello sottostante.

## Formulazione comprensibile

Il primo livello può dire «Il termine X caratterizza maggiormente il gruppo B» solo
se la struttura del finding identifica soggetto, direzione, grandezza e regola che
autorizza tale frase. Il livello successivo espone immediatamente frequenze,
denominatori, test, p-value corretto, effect size, intervallo e caveat applicabili.

Valori arrotondati **DEVONO** conservare accesso al valore e all'unità effettivi. La
microcopy non può trasformare associazione in causalità, assenza di evidenza in
evidenza di assenza o significatività in importanza pratica.

## EvidenceAssessment

Non esiste un confidence score universale. Una valutazione di solidità è un
artefatto strutturato composto, quando pertinente, da:

- qualità e copertura dell'input;
- adeguatezza del disegno e rispetto delle precondizioni;
- numerosità ed effettiva unità indipendente;
- grandezza dell'effetto e relativa incertezza;
- supporto statistico con correzione multipla applicabile;
- dispersione, stabilità e sensibilità a parametri o campionamento;
- rappresentatività e rischio di dominanza di poche unità;
- completezza del lineage.

Ogni famiglia analitica può definire una `SupportPolicy` versionata che traduce tali
dimensioni in categorie localizzabili come `strong`, `moderate`, `weak`, `caution`
o `insufficient`. La policy **DEVE** dichiarare soglie, rationale, dominio e casi nei
quali non produce alcuna categoria. La categoria conserva le dimensioni che l'hanno
determinata e non le sostituisce.

## Regole di presentazione

- `strong`, `moderate` e `weak` descrivono supporto secondo una policy specifica,
  non verità universale.
- `caution` accompagna un finding soltanto se la proposizione resta difendibile.
- `insufficient` sopprime la conclusione non sostenibile e spiega che cosa manca.
- Colore o icona non sono l'unico segnale della categoria.
- Un'etichetta non è prodotta se manca una policy scientificamente difendibile.
- L'utente può aprire regola, versione e fattori che hanno determinato l'esito.

## Verifica

I test confrontano struttura, frase localizzata ed evidenza per impedire inversioni,
omissioni di caveat e arrotondamenti ingannevoli. Studi con persone rappresentative
misurano comprensione di conclusione, incertezza, limiti e distinzione tra
associazione e causalità.
