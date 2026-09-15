<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Similarità e distanze

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-13 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline da revisionare |
| Documento padre | [GS-MET-001](README.md) |

## Domini distinti

Una misura **DEVE** dichiarare se opera su insiemi, vettori o distribuzioni di
probabilità. Allineamento delle dimensioni, vocabolario, weighting, normalizzazione
e trattamento dei mancanti sono parte dell'input semantico.

## Insiemi

Per insiemi finiti `A` e `B`:

```text
JaccardSet-v1 = |A∩B| / |A∪B|
DiceSet-v1    = 2|A∩B| / (|A|+|B|)
```

Per due insiemi vuoti entrambe valgono `1`; per un solo insieme vuoto valgono `0`.
Varianti multiset o pesate richiedono altro identificatore.

## Vettori reali

Per vettori allineati `x,y ∈ ℝ^n`:

```text
Cosine-v1    = (x·y) / (||x||₂ ||y||₂), norme entrambe positive
Euclidean-v1 = sqrt[Σ(x_i-y_i)²]
Manhattan-v1 = Σ|x_i-y_i|
```

Il coseno è non definito per un vettore nullo. `1-cosine` **NON DEVE** essere
chiamata metrica senza una variante e una dichiarazione delle proprietà, perché in
generale non soddisfa la disuguaglianza triangolare.

## Distribuzioni di probabilità

La divergenza di Kullback–Leibler (KL), la divergenza/distanza di Jensen–Shannon
(JS) e la distanza di Hellinger operano soltanto su distribuzioni normalizzate.

Siano `p_i,q_i≥0`, `Σp=Σq=1`, `m=(p+q)/2`, con logaritmo base 2:

```text
KL-v1(p||q) = Σ_i p_i log2(p_i/q_i)
JSdiv-v1    = 0,5 KL(p||m) + 0,5 KL(q||m)
JSdist-v1   = sqrt(JSdiv-v1)
Hellinger-v1 = sqrt[Σ_i(sqrt(p_i)-sqrt(q_i))²] / sqrt(2)
```

Il contributo con `p_i=0` è zero. Kullback–Leibler è finita soltanto se `q_i>0` ovunque `p_i>0`;
è direzionale e **NON È** una metrica. JSdiv è una divergenza; la sua radice è la
distanza. Hellinger e JSdist sono metriche nelle condizioni dichiarate. Smoothing e
rinormalizzazione sono trasformazioni separate, mai implicite.

## Proprietà e verifica

Ogni implementazione dichiara range, simmetria e proprietà metriche. Le fixture
coprono identità, disgiunzione, zeri, dimensioni non allineate e probabilità non
normalizzate. Per le distanze metriche si verificano non negatività, identità,
simmetria e disuguaglianza triangolare su casi generati; i risultati sono confrontati
con un'implementazione indipendente entro la tolleranza approvata.
