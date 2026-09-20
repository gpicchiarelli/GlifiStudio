<!-- SPDX-License-Identifier: BSD-3-Clause -->

# GS-WVR-002 — Baseline di design con CI bloccata dal budget

| Campo | Valore |
| --- | --- |
| Identificatore | GS-WVR-002 |
| Tipo | Deroga controllata |
| Versione | 1.0.0 |
| Stato | Approvata, temporanea |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | Richiesta dell'iniziatore di operare, committare e pubblicare direttamente la baseline nel repository privato |
| Regole interessate | GS-REP-002; GS-STD-001-20; integrazione tramite pull request e con check remoti verdi |
| Ambito | Commit `6df92ca` della baseline di design e follow-up documentale che registra questa deroga |
| Scadenza | 2026-09-22 o ripristino del budget Actions, se precedente |

## Motivazione

La baseline GS-DSG richiesta è stata integrata direttamente nel repository privato
in profilo solo-owner. I workflow `Verifica` e `App Store preflight` sono stati
creati per `6df92ca`, ma entrambi hanno concluso senza eseguire alcuno step. Le
annotazioni GitHub dichiarano che un budget Actions impedisce ulteriore utilizzo.
La limitazione è del provider e non un fallimento osservato di codice o test.

Il ruleset protettivo non è disponibile sul piano corrente; il repository conserva
la configurazione dichiarativa pronta per l'attivazione. La deroga non autorizza
ulteriori modifiche dirette a `main`.

## Rischio e impatto

- manca una ripetizione indipendente su runner Xcode 27 del gate locale;
- il cambiamento è prevalentemente normativo e modifica il validatore documentale,
  non codice prodotto, dipendenze, entitlement, firma o workflow;
- l'assenza di pull request elimina il secondo passaggio di review asincrona;
- un errore specifico del checkout remoto potrebbe emergere al ripristino del budget.

## Mitigazione

- `make verify` e `make verify-app-store` sono stati eseguiti due volte sullo stato
  finale con Xcode 27.0 e Apple Swift 6.4;
- metadati, 167 ID, link e sequenze RF/RQ/TV sono verificati automaticamente;
- build Debug/Release, test Swift, analisi statica e archivi senza firma macOS e
  iPadOS sono superati;
- remote `main`, commit locale e commit remoto sono stati confrontati;
- l'evidenza GS-VER-015 distingue esplicitamente prova documentale e futura prova
  implementativa.

## Verifica compensativa

GS-VER-015 registra ambiente, controlli, risultati e limiti. I run GitHub
`34965002983` e `34965002861` documentano la creazione dei job e la mancata
assegnazione del runner (`steps: []`, `runner_id: 0`) per budget.

## Piano di rientro

1. riattivare il budget Actions entro la scadenza;
2. rieseguire `Verifica` e `App Store preflight` sulla revisione finale;
3. confrontare il risultato col gate locale e correggere eventuali divergenze;
4. chiudere questa deroga soltanto dopo entrambi i workflow verdi;
5. usare branch e pull request per le modifiche successive, anche in profilo solo,
   salvo emergenza distinta e registrata.

Se il budget non viene ripristinato entro la scadenza, la deroga diventa una non
conformità da riesaminare prima di ulteriori integrazioni.

## Riferimenti

- [Workflow Verifica](https://github.com/gpicchiarelli/GlifiStudio/actions/runs/34965002983)
- [Workflow App Store preflight](https://github.com/gpicchiarelli/GlifiStudio/actions/runs/34965002861)
- [GS-VER-015](../evidenze/GS-VER-015-specifiche-di-design.md)
