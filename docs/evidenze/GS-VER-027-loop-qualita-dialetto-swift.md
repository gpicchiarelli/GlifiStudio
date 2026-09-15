<!-- SPDX-License-Identifier: BSD-3-Clause -->

# GS-VER-027 — Loop di qualità e dialetto Swift

| Campo | Valore |
| --- | --- |
| Identificatore | GS-VER-027 |
| Tipo | Evidenza di verifica del loop di qualità |
| Versione | 1.0.0 |
| Stato | Superato parzialmente in ambiente cloud Linux |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | Evidenza osservata dei controlli eseguibili senza Xcode |

## Ambito

- requisiti coperti: CV-020;
- verifiche coperte: TV-049 (porzione statica), predisposizione del loop GS-DEV-002;
- ambiente cloud Linux: Python 3.12, assenza di Xcode, `swift`, `xcodebuild` e `zsh`;
- artefatti: `Scripts/check-swift-dialect.py`, `Scripts/format.sh`,
  `Scripts/quality.sh`, Makefile, `.github/workflows/ci.yml`, ADR-0020.

## Procedura

1. ispezione di Package.swift, `Config/Base.xcconfig`, `.swift-format`, Makefile e
   workflow CI rispetto al contratto ADR-0015/ADR-0020;
2. esecuzione di `./Scripts/check-swift-dialect.py`;
3. esecuzione dei controlli Python del gate (`check-docs`, `check-repository`,
   `check-github-config`, `check-compliance`, `check-fixtures`, `check-naming`,
   `check-secrets`, `check-localization`, `check-apple-baseline`,
   `check-app-store-baseline`) quando indipendenti da Xcode;
4. tentativo di `make verify` e dichiarazione esplicita dei prerequisiti mancanti.

## Risultato osservato

- il controllo dialettale riconosce tools 6.4, language mode 6, concurrency
  completa, le regole `.swift-format` obbligatorie e i target Make/CI;
- la CI dichiara `static-quality` (Ubuntu), `format-check` e `verify` (Xcode 27),
  più cache SPM su `verify` e `app-store-baseline`;
- in questo ambiente sono superati: `make quality-static` e i relativi controlli
  Python/zsh (`check-swift-dialect`, `check-docs`, `check-repository`,
  `check-github-config`, `check-naming`, `check-secrets`, `check-compliance`,
  `check-fixtures`, `check-architecture`, `check-localization`,
  `check-apple-baseline`, `check-app-store-baseline`);
- `make verify` e `make format`/`lint` non sono eseguibili in questo ambiente
  cloud per assenza di Apple Swift/Xcode 27 e SDK macOS/iPadOS (`swift`,
  `xcodebuild`, `xcrun` mancanti). `zsh` è disponibile dopo installazione locale
  di supporto, ma non sostituisce la toolchain Apple.

## Limiti

Non prova formattazione `swift format`, unit test SwiftPM, smoke CLI né build
Debug/Release. La CI remota su runner `xcode-27` resta l'ambiente di prova
completo; un budget Actions insufficiente può impedirne l'avvio.

## Esito

**Superato localmente per la porzione statica/documentale.** La porzione Swift e
Xcode è pronta in configurazione e demandata ai runner macOS dichiarati.
