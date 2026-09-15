<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Fondazione statistica e inferenza

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-21 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline da revisionare |
| Documento padre | [GS-MET-001](README.md) |

## Selezione del metodo

Un test **DEVE** partire da domanda, unità indipendente, disegno, variabili, ipotesi,
sampling e assunzioni; non dal nome della funzione disponibile. Il risultato
conserva statistica, gradi di libertà, alternativa, p-value, effect size, intervallo
di confidenza, esclusioni e diagnostica applicabili. Un p-value **NON È** la
probabilità che l'ipotesi nulla sia vera.

## Famiglie iniziali

| Famiglia | Dominio e variante richiesta |
| --- | --- |
| Chi-quadrato/G/Fisher | conteggi categoriali secondo GS-MET-001-08/09 |
| `PearsonR-v1` | coppie quantitative finite; `r=Σ(x-x̄)(y-ȳ)/sqrt[Σ(x-x̄)²Σ(y-ȳ)²]`, varianze positive |
| `SpearmanRho-v1` | Pearson sui ranghi medi in presenza di tie; p-value esatto, permutation o asintotico dichiarato |
| t-test | one-sample, paired o independent-Welch come varianti distinte; unità indipendenti e assunzioni diagnosticate |
| Wilcoxon/Mann–Whitney | signed-rank o rank-sum distinti; tie, zeri e metodo esatto/asintotico dichiarati |
| ANOVA | disegno, contrasto, omoscedasticità e post-hoc dichiarati; Welch è variante distinta |
| Kruskal–Wallis | gruppi indipendenti, ranking con tie correction e post-hoc separato |

Il t-test indipendente candidato è Welch, che non assume varianze uguali. Cohen's
`d-pooled-v1` usa invece, soltanto quando motivato,
`s_p=sqrt{[(n_1-1)s_1²+(n_2-1)s_2²]/(n_1+n_2-2)}` e
`d=(x̄_1-x̄_2)/s_p`, con gruppi indipendenti, `n_1,n_2≥2` e `s_p>0`. Effetti paired,
Welch o piccoli campioni richiedono effect size e correzioni distinti.

### Varianti candidate completamente identificate

`WelchT-v1` richiede due campioni indipendenti con `n_1,n_2≥2` e varianze finite
positive:

```text
t = (x̄_1-x̄_2) / sqrt(s_1²/n_1+s_2²/n_2)
ν = (s_1²/n_1+s_2²/n_2)² /
    [(s_1²/n_1)²/(n_1-1)+(s_2²/n_2)²/(n_2-1)]
```

`PairedT-v1` applica il one-sample t-test alle differenze appaiate; coppie incomplete
sono escluse secondo policy dichiarata. `OneSampleT-v1` usa
`t=(x̄-μ₀)/(s/sqrt(n))`, `df=n-1`, con `n≥2` e `s>0`. Alternativa unilaterale o
bilaterale e ipotesi `μ₀` sono persistite.

`MannWhitneyU-v1` assegna midrank al campione pooled e calcola
`U_1=R_1-n_1(n_1+1)/2`; lato del test, forma esatta o asintotica e correzione dei tie
sono espliciti. `WilcoxonSignedRank-v1` rimuove differenze zero secondo la policy
risolta, assegna midrank a `|d_i|` e usa la somma dei ranghi positivi; esatto e
asintotico sono varianti distinte.

`OneWayANOVA-v1` usa
`F=[Σ_g n_g(x̄_g-x̄)²/(k-1)]/[Σ_gΣ_i(x_gi-x̄_g)²/(N-k)]`, richiede gruppi
indipendenti, residui compatibili con il modello e varianza comune per l'inferenza.
`KruskalWallis-v1` usa midrank pooled e
`H=12/[N(N+1)]Σ_g R_g²/n_g-3(N+1)`, con fattore di correzione dei tie dichiarato.
Un risultato omnibus significativo non identifica da solo i gruppi differenti;
post-hoc e relativa famiglia multipla sono nodi separati.

## Intervalli, bootstrap e permutation test

Ogni intervallo di confidenza dichiara parametro, livello, metodo e assunzioni.
`BootstrapPercentile-v1` ricampiona con sostituzione l'unità indipendente `B` volte,
registra PRNG/seed e usa i quantili dichiarati della distribuzione bootstrap. Non è
valido se il resampling rompe dipendenze del disegno.

Un permutation test dichiara statistica, gruppo di permutazioni compatibile con
l'ipotesi nulla, alternativa, enumerazione esatta o Monte Carlo, numero di campioni,
seed e correzione del p-value Monte Carlo. L'exchangeability è una precondizione,
non un dettaglio implementativo.

## Confronti multipli

La famiglia di `m` ipotesi **DEVE** essere definita prima dell'interpretazione.

```text
Bonferroni-v1: p_adj_i = min(1, m p_i)

BenjaminiHochberg-v1:
  ordina p_(1)≤…≤p_(m)
  q_(i) = min(1, min_{j≥i} [m p_(j)/j])
  ripristina l'ordine originale
```

Bonferroni controlla il family-wise error rate; BH controlla la false discovery
rate nelle condizioni del metodo. P-value grezzi e corretti **DEVONO** entrambi
restare disponibili. Un'analisi su migliaia di termini **NON DEVE** presentare
p-value non corretti come evidenza conclusiva.

## Effect size

Cramér's V, odds ratio, log ratio e Cohen's d si usano soltanto nei domini definiti
nei rispettivi documenti. Effect size, intervallo d'incertezza e significatività
sono campi separati. Etichette qualitative come “piccolo” o “grande” richiedono una
soglia motivata per il dominio e non sono predefinite.

## Fondazione matematica e backend

La fondazione concettuale `GlifiMath` comprende statistica descrittiva e
inferenziale, algebra lineare, matrici sparse, similarità/distanze, grafi,
ottimizzazione e pseudo-casualità controllata. Non è ancora un target Swift
obbligatorio. Swift, Accelerate, BNNS, Core ML e Metal/MPS sono backend: **NON
DEVONO** definire la semantica scientifica. Ogni backend ha riferimento indipendente,
tolleranze e benchmark end-to-end.

## Verifica

Dataset di riferimento coprono risultati noti, estremi, `NaN`, overflow, campioni
piccoli, tie e assunzioni violate. Property test verificano invarianti; reference
test confrontano almeno un'implementazione indipendente; simulation test controllano
errore di tipo I, coverage o potenza quando appropriato.

## Riferimento scientifico

- Benjamini e Hochberg, [Controlling the False Discovery Rate](https://doi.org/10.1111/j.2517-6161.1995.tb02031.x), 1995.
