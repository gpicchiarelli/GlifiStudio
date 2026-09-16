<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Loop di sviluppo e qualità

| Campo | Valore |
| --- | --- |
| Identificatore | GS-DEV-002 |
| Tipo | Guida controllata del loop di sviluppo |
| Versione | 1.1.0 |
| Stato | Bozza controllata |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Scopo

Questo documento definisce il loop quotidiano di qualità di **Glifi Studio**:
formattazione Apple `swift-format`, dialetto Swift 6, controlli statici e
equivalenza con la CI. Integra [GS-DEV-001](ambiente-di-sviluppo.md) senza
sostituire il gate completo `make verify`.

## Ingressi canonici

| Comando | Quando | Effetto |
| --- | --- | --- |
| `make format` | Prima di commitare sorgenti Swift | Riscrive `Apps` e `Packages` secondo `.swift-format` |
| `make lint` / `make format-check` | Dopo `format` o in revisione | Controlla lo stile senza modificare i file |
| `make check-swift-dialect` | Sempre nel loop e nel gate | Verifica language mode, concurrency, regole e CI |
| `make quality-static` | Iterazione senza toolchain Swift | Docs, compliance, segreti, dialetto e baseline statiche |
| `make quality` | Iterazione locale rapida | `quality-static` + formattazione, senza build Xcode |
| `make verify` | Prima di integrare | Gate completo locale, identico al job CI `verify` |
| `make verify-app-store` | Modifiche ad app o distribuzione | Gate packaging senza firma |

Non introdurre hook git obbligatori: il loop primario è Makefile + CI, come deciso
in ADR-0020.

## Dialetto Swift

Il progetto usa esclusivamente:

- Apple Swift 6.4 o successiva compatibile della serie 6 in Xcode 27;
- Swift 6 language mode (`SWIFT_VERSION = 6.0`, `swiftLanguageModes: [.v6]`);
- `swift-tools-version: 6.4`;
- `SWIFT_STRICT_CONCURRENCY = complete`;
- avvisi trattati come errori;
- formattazione tramite `swift format` e `.swift-format` versionato.

Non si adotta SwiftLint come autorità stilistica: le regole linguistiche e di
stile vivono in `.swift-format` e nei controlli `check-toolchain` /
`check-swift-dialect`. Feature upcoming o sperimentali globali richiedono ADR.

## Sequenza consigliata

```sh
make bootstrap
make format
make quality
make verify
```

Durante lo sviluppo di un package, `make quality` riduce il ciclo di feedback.
Prima della pull request, `make verify` resta obbligatorio. Per modifiche ad app,
privacy, packaging o metadati App Store eseguire anche `make verify-app-store`.

## CI

`.github/workflows/ci.yml` esegue:

1. `static-quality` (Ubuntu) — docs, tracciabilità/compliance, segreti, naming,
   repository, GitHub config, fixture, architettura, localizzazione, baseline
   Apple/App Store e dialetto Swift, senza Xcode;
2. `format-check` (Xcode 27) — dialetto machine-readable e `swift format` strict;
3. `verify` (Xcode 27) — `Scripts/verify.sh` con cache SPM, dopo i due early-fail.

`.github/workflows/app-store.yml` esegue `app-store-baseline` (Xcode 27) con cache
SPM e `Scripts/verify-app-store.sh`.

I check richiesti dalla ruleset restano `verify` e `app-store-baseline`. Un
fallimento statico, di stile o dialetto blocca l'integrazione; indebolire un
controllo per ottenere verde è non conformità.

## Riferimenti

- [Ambiente di sviluppo](ambiente-di-sviluppo.md)
- [Implementazione Swift](standard/12-implementazione-swift.md)
- [Integrazione continua e quality gate](standard/20-integrazione-continua-e-quality-gate.md)
- [CI e runner Xcode 27](repository/05-ci-e-runner-xcode.md)
- [ADR-0020](adr/0020-loop-di-qualita-e-dialetto-swift.md)
