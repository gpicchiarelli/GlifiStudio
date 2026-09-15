# Glifi Studio

Glifi Studio è un ambiente nativo per macOS e iPadOS dedicato all'acquisizione, all'organizzazione e all'analisi di documenti, corpus e grandi collezioni testuali.

Il progetto è attualmente nella fase di definizione. La documentazione raccolta in `docs/` consolida i due documenti di appunti iniziali e costituisce la base controllata da cui far evolvere requisiti, architettura e piano di sviluppo.

## Ambiente Xcode

La baseline eseguibile comprende due app SwiftUI native, una per macOS e una per iPadOS, costruite sopra il package locale condiviso `GlifiCore`.

Aprire [GlifiStudio.xcworkspace](GlifiStudio.xcworkspace) e scegliere uno degli schemi condivisi `GlifiStudio-macOS` o `GlifiStudio-iPadOS`. Per verificare l'intera baseline:

```sh
make bootstrap
make verify
```

Prerequisiti, struttura e convenzioni operative sono descritti nella [Guida dell'ambiente di sviluppo](docs/ambiente-di-sviluppo.md).

Il nome visibile, i nomi tecnici e le eccezioni di provenienza sono definiti in [Identità e convenzioni di denominazione](docs/identita-del-progetto.md).

## Repository privato

Remote canonico: [github.com/gpicchiarelli/GlifiStudio](https://github.com/gpicchiarelli/GlifiStudio).

La baseline include governo, contributi, sicurezza, supporto, modelli di issue e pull request, etichette, ruleset per maintainer singolo o team, Dependabot e CI Apple Silicon su Xcode 27. Il quality gate locale e remoto ha un unico ingresso:

```sh
make verify
```

La configurazione operativa e la procedura ripetibile di attivazione sono raccolte in [Governo del repository](docs/repository/README.md) e [Bootstrap GitHub](docs/repository/09-bootstrap-github.md). Non sono inclusi segreti, firma Apple o pubblicazione automatica finché team e profili non saranno assegnati.

## Preparazione App Store

Il canale iniziale approvato è App Store **non in elenco**: la pagina non sarà
ricercabile e l'app sarà raggiungibile tramite link diretto, dopo la normale App
Review. La baseline include identità multipiattaforma, icona candidata, metadati
italiano/inglese, dichiarazioni privacy e accessibilità, piano TestFlight, matrice di
qualità, pacchetto di revisione e gate fail-closed.

```sh
make check-app-store
make verify-app-store
make app-store-submission-check
```

L'ultimo controllo deve fallire finché prodotto, firma, dispositivi, URL pubblici,
screenshot e approvazioni Apple non sono realmente completati. Il piano dettagliato
è in [Preparazione App Store](docs/app-store/README.md).

## Standard documentale

La documentazione adotta un profilo proporzionato al progetto basato su:

- ISO/IEC/IEEE 15289:2019 per organizzazione e controllo degli information item del ciclo di vita;
- ISO/IEC/IEEE 29148:2018 per necessità degli stakeholder, requisiti software e tracciabilità;
- ISO/IEC/IEEE 42010:2022 per la descrizione dell'architettura;
- ISO/IEC 25010:2023 come tassonomia delle caratteristiche di qualità.

Ambito, regole e limiti della conformità sono definiti nel [Piano di documentazione](docs/piano-documentazione.md). Non viene dichiarata una certificazione ISO formale.

Lo [Standard di progetto Glifi Studio](docs/standard-di-progetto.md) indicizza documenti normativi autonomi per ciclo di vita, requisiti, architettura, implementazione, qualità, sicurezza e rilascio.

## Principi guida

- correttezza e tracciabilità prima della convenienza;
- scalabilità come requisito architetturale, non come estensione futura;
- separazione netta tra prodotto interattivo e motore computazionale;
- elaborazione incrementale senza obbligo di caricare l'intero corpus in memoria;
- architettura Apple-native, con Swift come linguaggio principale;
- ottimizzazioni motivate da benchmark e profiling riproducibili;
- collegamento preservato tra risultati analitici, trasformazioni e fonti originali.

## Mappa della documentazione

- [Indice della documentazione](docs/README.md)
- [Standard di progetto](docs/standard-di-progetto.md)
- [Piano di documentazione e profilo degli standard](docs/piano-documentazione.md)
- [Identità e convenzioni di denominazione](docs/identita-del-progetto.md)
- [Visione e principi](docs/visione-e-principi.md)
- [Architettura](docs/architettura.md)
- [Requisiti](docs/requisiti.md)
- [Matrice di tracciabilità](docs/tracciabilita.md)
- [Glossario](docs/glossario.md)
- [Roadmap iniziale](docs/roadmap.md)
- [Baseline linguistica italiana](docs/localizzazione-italiana.md)
- [Internazionalizzazione dell'interfaccia](docs/internazionalizzazione-interfaccia.md)
- [Pratiche e portafoglio tecnologico Apple](docs/apple/README.md)
- [Governo del repository privato](docs/repository/README.md)
- [Preparazione App Store](docs/app-store/README.md)
- [Decisioni aperte](docs/decisioni-aperte.md)
- [Decisioni architetturali](docs/adr/README.md)
- [Evidenze di verifica](docs/evidenze/README.md)

## Materiale di origine

I file [appunti-1.txt](appunti-1.txt) e [appunti 2.txt](appunti%202.txt) restano conservati come fonti grezze. Entrambi risultano incompleti e non sono considerati specifiche normative.

## Licenza

Glifi Studio è distribuito secondo la [BSD 3-Clause License](LICENSE), identificatore SPDX `BSD-3-Clause`. La [politica di licenza](docs/licenza.md) ne definisce ambito e gestione nel progetto.
