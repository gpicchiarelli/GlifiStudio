<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Distribuzioni lessicali, Zipf e Heaps

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-05 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline da revisionare |
| Documento padre | [GS-MET-001](README.md) |

## Osservazioni empiriche

Glifi Studio distingue tre artefatti osservati:

- distribuzione di frequenza: coppie `(TermID, f)` con ordinamento dichiarato;
- rank-frequency: coppie `(r, f_r)` ordinate per frequenza decrescente e tie-break
  stabile su `TermID`;
- frequency spectrum: coppie `(k, V_k)`, dove `V_k` è il numero di type osservati
  esattamente `k` volte.

La curva di crescita del vocabolario è la sequenza `V(n)` dei type distinti dopo i
primi `n` token. Dipende dall'ordine dei token: concatenazione dei documenti,
ordinamento e checkpoint **DEVONO** essere persistiti. Una media su permutazioni è
un artefatto differente e, se campionato, registra PRNG e seed.

## Modelli di Zipf

Il modello non traslato candidato è `f(r) = C r^(-α)` per `C > 0`, `α > 0`; la
variante Zipf–Mandelbrot è `f(r) = C(r + b)^(-α)` con dominio e vincoli di `b`
dichiarati. I conteggi osservati restano separati dai valori previsti.

`ZipfLogOLS-v1` è una procedura diagnostica completamente definita: su un intervallo
persistito di ranghi con frequenze positive pone `x=ln(r)`, `y=ln(f)`, stima
`y=β₀+β₁x` mediante minimi quadrati ordinari e restituisce `C=exp(β₀)`, `α=-β₁`.
Registra numerosità, `R²` e RMSE nello spazio logaritmico, residui e intervallo dei
ranghi. **NON DEVE** essere presentata come prova che i dati seguano una power law.
Altri estimator, troncamenti o smoothing richiedono identificatore distinto.

## Modello di Heaps

Il modello candidato è `V(n)=K n^β` per `K>0`, `0<β≤1`. `HeapsLogOLS-v1` applica
OLS a `ln V(n)=ln K+β ln n` sui checkpoint positivi esplicitamente registrati e
restituisce `K`, `β`, `R²`, RMSE logaritmico e residui. Non autorizza estrapolazioni
oltre l'intervallo osservato senza intervallo d'incertezza e avviso.

## Separazione obbligatoria

Ogni analisi di legge empirica **DEVE** mostrare separatamente:

1. osservazioni e regole di conteggio;
2. famiglia e formula del modello;
3. procedura di fitting, supporto, esclusioni e inizializzazione;
4. bontà dell'adattamento nello spazio in cui è ottimizzata;
5. residui e incertezza applicabile;
6. avviso che l'adattamento non stabilisce una legge esatta o un meccanismo causale.

## Scalabilità e verifica

Frequenze, spectrum e crescita ai checkpoint **DEVONO** essere calcolabili in modo
incrementale; l'ordinamento finale può operare esternamente alla memoria. Le fixture
verificano legami `Σ_k V_k = V` e `Σ_k kV_k = N`, stabilità dei tie, curve note e
fitting su dati sintetici con parametri noti e rumore controllato.

## Riferimento scientifico

- Lü, Zhang e Zhou, [Deviation of Zipf's and Heaps' Laws in Human Languages with Limited Dictionary Sizes](https://doi.org/10.1038/srep01082), 2013.
