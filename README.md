<!-- SPDX-License-Identifier: BSD-3-Clause -->

<p align="center">
  <img src="Design/AppIcon/AppIcon-master-1024.png" width="88" height="88" alt="Icona di Glifi Studio">
</p>

# Glifi Studio

<p align="center">
  <strong>Documenti, corpus e analisi testuale. Con rigore, fino alla fonte.</strong>
</p>

<p align="center">
  Ambiente computazionale Apple-native per trasformare grandi collezioni testuali in risultati verificabili, riproducibili e navigabili.
</p>

<p align="center">
  <a href="https://github.com/gpicchiarelli/GlifiStudio/actions/workflows/ci.yml"><img alt="Verifica" src="https://github.com/gpicchiarelli/GlifiStudio/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/gpicchiarelli/GlifiStudio/actions/workflows/app-store.yml"><img alt="App Store preflight" src="https://github.com/gpicchiarelli/GlifiStudio/actions/workflows/app-store.yml/badge.svg"></a>
  <a href="CHANGELOG.md"><img alt="Versione 0.1.0" src="https://img.shields.io/badge/versione-0.1.0-6557d2.svg"></a>
  <a href="#stato-del-progetto"><img alt="Stato: baseline ingegneristica" src="https://img.shields.io/badge/stato-baseline%20ingegneristica-c9835a.svg"></a>
  <a href="Packages/GlifiCore/Package.swift"><img alt="Swift 6" src="https://img.shields.io/badge/Swift-6.0-F05138.svg?logo=swift&logoColor=white"></a>
  <a href="docs/ambiente-di-sviluppo.md"><img alt="Xcode 27" src="https://img.shields.io/badge/Xcode-27-147EFB.svg?logo=xcode&logoColor=white"></a>
  <a href="docs/apple/README.md"><img alt="Piattaforme: macOS 27 e iPadOS 27" src="https://img.shields.io/badge/piattaforme-macOS%2027%20%7C%20iPadOS%2027-315CFF.svg?logo=apple&logoColor=white"></a>
  <a href="docs/internazionalizzazione-interfaccia.md"><img alt="Interfaccia: italiano e inglese" src="https://img.shields.io/badge/interfaccia-it%20%7C%20en-6c63d9.svg"></a>
  <a href="docs/app-store/README.md"><img alt="Distribuzione: App Store non in elenco" src="https://img.shields.io/badge/distribuzione-App%20Store%20non%20in%20elenco-4f5eb8.svg?logo=appstore&logoColor=white"></a>
  <a href="docs/repository/README.md"><img alt="Repository privato" src="https://img.shields.io/badge/repository-privato-2f3136.svg?logo=github&logoColor=white"></a>
  <a href="LICENSE"><img alt="Licenza BSD 3-Clause" src="https://img.shields.io/badge/licenza-BSD--3--Clause-214237.svg"></a>
</p>

![Laboratorio di analisi testuale di Glifi Studio](docs/assets/glifistudio-hero.png)

Glifi Studio è un ambiente professionale nativo per macOS e iPadOS dedicato all’acquisizione, all’organizzazione e all’analisi quantitativa e qualitativa di documenti, corpus e grandi collezioni testuali.

L’unità di lavoro è un **progetto persistente**, non un singolo file. Fonti, metadati, trasformazioni, indici, parametri e risultati restano collegati in una catena di provenienza ispezionabile: ogni risultato deve poter tornare al documento e al passaggio che lo hanno prodotto.

```text
acquisizione → estrazione → normalizzazione → segmentazione
            → tokenizzazione → annotazione → indicizzazione
            → analisi → esplorazione → fonte originale
```

Glifi Studio non è un editor generalista con qualche statistica aggiunta e non è una semplice utility per contare parole. Il progetto separa il prodotto interattivo dal motore computazionale, tratta la scalabilità come vincolo architetturale e ammette ottimizzazioni soltanto quando benchmark e profiling ne dimostrano il valore.

## Stato del progetto

> [!IMPORTANT]
> **Baseline ingegneristica eseguibile — non ancora un prodotto pronto al rilascio.** Le app macOS e iPadOS, il package condiviso, il contratto applicativo, la CLI headless, la localizzazione iniziale e i quality gate sono operativi. Importazione, persistenza dei progetti, indicizzazione e capacità analitiche appartengono ancora alle fasi di validazione e sviluppo descritte nella [roadmap](docs/roadmap.md).

La documentazione è una baseline controllata: requisiti, architettura e decisioni aperte sono tracciati, ma non tutte le scelte di prodotto hanno ancora approvazione definitiva. La presenza di una tecnologia o di un documento non equivale alla disponibilità della relativa funzione.

| Superficie | Baseline attuale |
| --- | --- |
| App macOS | Shell SwiftUI nativa, localizzata e accessibile, collegata a `GlifiKit` |
| App iPadOS | Stessa baseline condivisa, adattata al target iPadOS |
| `GlifiKit` | Contratto pubblico minimo e indipendente dalla presentazione |
| `GlifiCore` | Motore headless actor-based con configurazione linguistica esplicita |
| `GlifiCLI` | Smoke test eseguibile del percorso senza interfaccia grafica |
| Qualità | Controlli di repository, segreti, toolchain, naming, documentazione, architettura, localizzazione, baseline Apple e App Store |
| Distribuzione | Preparazione controllata per App Store non in elenco; firma, dispositivi, materiali e approvazioni reali restano fail-closed |

## Principi di progetto

- **Correttezza prima della convenienza.** Significato, unità, offset e trasformazioni devono essere definiti e verificabili.
- **Provenienza come parte del dato.** Versione del corpus, fonte, parametri e artefatti derivati viaggiano insieme al risultato.
- **Elaborazione incrementale.** La dimensione del corpus può cambiare il costo, non obbligare l’intera collezione a risiedere in memoria.
- **Confini piccoli e sostituibili.** Interfaccia, API, motore, persistenza e backend di calcolo evolvono senza dipendenze inverse.
- **Prestazioni dimostrate.** CPU, Accelerate, Core ML, Metal e altri percorsi vengono promossi soltanto su misure end-to-end riproducibili.
- **Esperienza Apple-native.** SwiftUI, Swift Concurrency e i framework di sistema vengono usati secondo disponibilità, accessibilità e comportamento reale sui dispositivi.
- **Automazione senza GUI.** Il motore deve restare utilizzabile tramite contratto pubblico e strumenti headless.

## Architettura

```text
┌──────────────────────────────────────────────────────────────┐
│             Glifi Studio · macOS / iPadOS                    │
│        esperienza nativa, navigazione, visualizzazione       │
└────────────────────────────┬─────────────────────────────────┘
                             │
                       ┌─────▼─────┐
                       │ GlifiKit  │  contratto applicativo
                       └─────┬─────┘
                             │
          ┌──────────────────▼──────────────────┐
          │              GlifiCore              │
          │ importazione · testo · corpus       │
          │ ricerca · analisi · provenienza     │
          └──────────────┬───────────┬──────────┘
                         │           │
                 persistenza    calcolo/linguistica
                         │           │
                         └─────┬─────┘
                               │
                 framework e servizi Apple

GlifiCLI ────────────────────► GlifiKit
```

La dipendenza procede dall’esterno verso l’interno: il dominio non dipende da SwiftUI, gli algoritmi non dipendono da una persistenza concreta e la GUI non determina il modello scientifico. La [descrizione dell’architettura](docs/architettura.md) definisce view, invarianti e corrispondenze; le [ADR](docs/adr/README.md) registrano le decisioni senza riscriverne retroattivamente il rationale.

## Avvio rapido

### Requisiti

- macOS con Xcode 27 e Command Line Tools selezionati;
- SDK macOS 27 e iOS/iPadOS 27;
- Swift 6;
- nessuna dipendenza runtime di terze parti nella baseline corrente.

### Workspace Xcode

```sh
make bootstrap
open GlifiStudio.xcworkspace
```

Usare il workspace, non il solo progetto, e scegliere uno degli schemi condivisi:

- `GlifiStudio-macOS`
- `GlifiStudio-iPadOS`

### Percorso headless

```sh
swift run --package-path Packages/GlifiCore GlifiCLI
```

Output atteso:

```text
GlifiCore pronto
```

La [guida dell’ambiente di sviluppo](docs/ambiente-di-sviluppo.md) descrive toolchain, build, schemi e convenzioni operative.

## Verifica

Il quality gate locale e quello CI condividono un unico ingresso:

```sh
make verify
```

Il gate controlla igiene e configurazione del repository, assenza di segreti e materiale di firma, toolchain, naming, documentazione, dipendenze architetturali, localizzazione, requisiti Apple, baseline App Store, formattazione Swift, test, smoke test CLI e build Debug/Release di entrambe le app senza firma.

Controlli mirati:

| Comando | Scopo |
| --- | --- |
| `make test` | Test dei package Swift |
| `make lint` | Formattazione Swift in modalità strict |
| `make build-macos` | Build Debug macOS senza firma |
| `make build-ipados` | Build Debug per simulatore iPadOS senza firma |
| `make check-app-store` | Coerenza della baseline App Store |
| `make verify-app-store` | Preflight di packaging e distribuzione |
| `make app-store-submission-check` | Gate fail-closed per una submission reale |

Le prove riproducibili vengono registrate nell’[indice delle evidenze](docs/evidenze/README.md); le eccezioni temporanee richiedono una [deroga controllata](docs/deroghe/README.md).

## Roadmap

Lo sviluppo riduce prima i rischi che possono invalidare l’architettura:

1. **Decisioni e fattibilità** — streaming, offset Unicode, identità, persistenza, benchmark e qualità linguistica.
2. **Vertical slice headless** — dal testo UTF-8 a vocabolario, indice, frequenze e query, con riapertura riproducibile.
3. **Primo flusso interattivo** — progetti, importazione, metadati, frequenze, concordanze e ritorno alla fonte su macOS e iPadOS.
4. **Documenti e corpus ricchi** — PDF, OCR tracciato, metadati, sottoinsiemi e prime analisi statistiche validate.
5. **Analisi avanzata** — servizi linguistici sostituibili, similarità, embedding e accelerazioni provate dai benchmark.

La sequenza, i criteri di uscita e la natura ancora proposta del piano sono definiti nella [roadmap completa](docs/roadmap.md).

## Struttura del repository

| Percorso | Responsabilità |
| --- | --- |
| [`Apps`](Apps) | App native macOS/iPadOS e risorse condivise |
| [`Packages/GlifiCore`](Packages/GlifiCore) | `GlifiCore`, `GlifiKit`, `GlifiCLI` e relativi test |
| [`Config`](Config) | Build settings, sandbox ed entitlement per piattaforma |
| [`Design`](Design) | Master e provenienza degli asset visivi |
| [`Distribution/AppStore`](Distribution/AppStore) | Metadati, privacy, review e materiali di distribuzione |
| [`Benchmarks`](Benchmarks) | Contratti e futuri risultati prestazionali riproducibili |
| [`Fixtures`](Fixtures) | Corpus e fixture sintetiche controllate |
| [`Scripts`](Scripts) | Bootstrap, controlli e quality gate |
| [`docs`](docs) | Standard, requisiti, architettura, decisioni ed evidenze |

## Documentazione essenziale

- [Indice della documentazione](docs/README.md)
- [Visione e principi](docs/visione-e-principi.md)
- [Specifica dei requisiti](docs/requisiti.md)
- [Architettura](docs/architettura.md)
- [Matrice di tracciabilità](docs/tracciabilita.md)
- [Standard di progetto](docs/standard-di-progetto.md)
- [Tecnologie e pratiche Apple](docs/apple/README.md)
- [Preparazione App Store](docs/app-store/README.md)
- [Decisioni aperte](docs/decisioni-aperte.md)
- [Registro ADR](docs/adr/README.md)

Gli appunti originari restano conservati come provenienza incompleta e non normativa. In caso di divergenza fanno fede documenti controllati, ADR accettate, codice e test, secondo l’ordine definito in [`AGENTS.md`](AGENTS.md).

## Contribuire e sicurezza

Prima di proporre una modifica, leggere le [regole di contribuzione](CONTRIBUTING.md) e le [istruzioni operative](AGENTS.md). Cambiamenti a formati persistenti, dipendenze, entitlement, rete, telemetria, sincronizzazione o backend richiedono requisiti e decisioni applicabili.

Le vulnerabilità non devono essere aperte come issue pubbliche: seguire la [policy di sicurezza](SECURITY.md). Per assistenza generale è disponibile la [policy di supporto](SUPPORT.md); ruoli e processo decisionale sono descritti in [GOVERNANCE.md](GOVERNANCE.md).

## Licenza

Glifi Studio è distribuito secondo la [BSD 3-Clause License](LICENSE), identificatore SPDX `BSD-3-Clause`. La [politica di licenza](docs/licenza.md) ne definisce ambito, attribuzioni e gestione dei materiali di terzi.
