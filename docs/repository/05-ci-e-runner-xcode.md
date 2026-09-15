# Integrazione continua e runner Xcode 27

| Campo | Valore |
| --- | --- |
| Identificatore | GS-REP-005 |
| Tipo | Descrizione della pipeline |
| Versione | 1.4.0 |
| Stato | Configurato localmente |
| Responsabile | Responsabile tecnico, da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline operativa richiesta dal promotore |

## Pipeline

`.github/workflows/ci.yml` esegue il quality gate su pull request, push a `main` e avvio manuale. Il job early-fail `swift-style` verifica dialetto Swift e formattazione. Il job obbligatorio `verify` usa il runner Apple Silicon `xcode-27`, dipende da `swift-style`, applica una cache SPM deterministica e esegue lo stesso `Scripts/verify.sh` usato localmente.

`.github/workflows/app-store.yml` aggiunge il job obbligatorio
`app-store-baseline`: ripete il gate completo e verifica analisi statica e archivi
senza firma per entrambe le piattaforme. Il gate di submission finale non gira in
CI finché richiede dati, firma e approvazioni esterne; viene invocato deliberatamente
con `make app-store-submission-check`.

Il gate verifica repository e segreti, Xcode 27, Apple Swift 6.4 o successiva
compatibile della serie 6, Swift 6 language mode, SwiftPM tools 6.4 e strict
concurrency completa. Verifica inoltre identità, documentazione, architettura,
localizzazione, baseline Apple, dialetto/formato Swift, test, smoke test CLI e build
Debug/Release di macOS e iPadOS senza firma.

Il loop locale rapido è documentato in [GS-DEV-002](../loop-di-sviluppo-e-qualita.md)
e deciso da ADR-0020: `make quality` non sostituisce `make verify`.

## Integrità della supply chain

`actions/checkout` e `actions/cache` sono fissate a commit SHA completi e non
conservano credenziali. Dependabot controlla settimanalmente soltanto GitHub
Actions. Non esistono dipendenze Swift esterne; la relativa automazione sarà
aggiunta solo insieme a una dipendenza approvata e dopo aver verificato il
supporto corrente del servizio.

Tag come `v5` sono leggibili ma mobili e non devono essere usati come riferimento eseguibile. L'annotazione del tag resta accanto allo SHA per consentire manutenzione e revisione.

## Runner e costi

Al 15 settembre 2026 il runner `xcode-27` è pubblicato da GitHub come immagine Apple Silicon in public preview e comprende Xcode 27 e gli SDK 27. La disponibilità, le caratteristiche e la tariffazione dei minuti per repository privati devono essere riverificate prima della creazione del remote e a ogni variazione del servizio.

L'immagine preview può cambiare. `Scripts/check-toolchain.sh` trasforma una variazione incompatibile in un fallimento esplicito invece di costruire con una toolchain diversa senza evidenza.

## Evoluzione

La cache SPM è attiva con chiave deterministica sul manifest e sui sorgenti del
package e non contiene segreti. Coverage, benchmark e test UI si introducono quando
esistono soglie reali. Workflow di firma e pubblicazione restano separati e
richiedono un ambiente protetto. Il packaging senza firma è obbligatorio e non
costituisce una release.

## Stato remoto iniziale

Sul primo push GitHub ha creato entrambi i job, ma non ha avviato step perché il
budget Actions dell'account impedisce ulteriore utilizzo. Questa condizione è un
blocco infrastrutturale: la CI non è verificata e non deve essere marcata verde o
sostituita da Xcode precedente. L'evidenza è [GS-VER-010](../evidenze/GS-VER-010-attivazione-github-privato.md).

## Riferimenti operativi

- [Immagine ufficiale del runner Xcode 27](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-Readme.md)
- [Runner ospitati da GitHub](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Catalogo e ciclo delle immagini runner](https://github.com/actions/runner-images)
- [Uso sicuro di GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
- [ADR-0020](../adr/0020-loop-di-qualita-e-dialetto-swift.md)
