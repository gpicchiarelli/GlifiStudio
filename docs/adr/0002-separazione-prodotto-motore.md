# ADR-0002 — Separazione tra prodotto e motore

| Campo | Valore |
| --- | --- |
| Identificatore | GS-ADR-0002 |
| Versione | 0.4.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Decisore | Da assegnare |
| Data proposta | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Fonte | Baseline candidata dagli appunti iniziali |
| Sostituisce | Nessuno |

## Contesto

Le stesse capacità computazionali devono servire l'app interattiva, test automatici, benchmark, elaborazioni batch e una possibile CLI. Incorporare la logica scientifica nella GUI renderebbe difficile verificarla, riutilizzarla ed evolverla.

## Decisione

Il prodotto interattivo e il motore computazionale sono componenti distinti:

```text
Glifi Studio → GlifiKit → GlifiCore
```

`Glifi Studio` gestisce presentazione e interazione per macOS e iPadOS. `GlifiKit`
espone un contratto applicativo piccolo, pre-1.0 e progettato per stabilizzarsi
secondo GS-API-001; la visibilità Swift `public` non promette ancora ABI o SDK
binario. `GlifiCore` implementa importazione, trasformazioni, indicizzazione,
ricerca e analisi senza dipendere da SwiftUI, AppKit o UIKit.

La separazione deve essere imposta dalla struttura di target e package e verificata automaticamente.

## Alternative considerate

- logica applicativa incorporata nel target GUI;
- motore separato senza livello API stabile;
- separazione a tre livelli Glifi Studio, GlifiKit e GlifiCore.

La terza alternativa è quella proposta perché sostiene riuso headless e controllo delle dipendenze. L'approvazione formale richiede un decisore nominato.

## Conseguenze

- La GUI diventa un client del motore.
- CLI, test headless e benchmark non duplicano la logica.
- I modelli esposti richiedono progettazione deliberata, contract test e una
  politica di compatibilità prima della stabilizzazione 1.0.
- Alcuni tipi di presentazione dovranno essere adattati ai modelli del dominio anziché attraversare direttamente i confini dei moduli.
