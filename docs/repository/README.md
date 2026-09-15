# Governo del repository

| Campo | Valore |
| --- | --- |
| Identificatore | GS-REP-IDX-001 |
| Tipo | Indice operativo del repository |
| Versione | 1.1.0 |
| Stato | Attivo |
| Responsabile | Amministratore del repository, provvisorio |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline operativa richiesta dal promotore |

Questa sezione traduce lo standard di progetto in una configurazione concreta per un repository inizialmente privato. Distingue ciò che è già presente nel filesystem da ciò che dovrà essere applicato sul servizio Git dopo la creazione del remote.

## Documenti

| ID | Argomento | Stato |
| --- | --- | --- |
| GS-REP-001 | [Modello di governo privato](01-modello-di-governo-privato.md) | Operativo |
| GS-REP-002 | [Strategia Git e pull request](02-strategia-git-e-pull-request.md) | Operativo |
| GS-REP-003 | [Configurazione GitHub](03-configurazione-github.md) | Da applicare al remote |
| GS-REP-004 | [Sicurezza del repository](04-sicurezza-del-repository.md) | Operativo e progressivo |
| GS-REP-005 | [CI e runner Xcode 27](05-ci-e-runner-xcode.md) | Configurato; da eseguire sul remote |
| GS-REP-006 | [Segreti e firma Apple](06-segreti-e-firma-apple.md) | Divieto attivo; provisioning rinviato |
| GS-REP-007 | [Backup e recupero](07-backup-e-recupero.md) | Da attivare con il remote |
| GS-REP-008 | [Passaggio futuro a pubblico](08-passaggio-a-pubblico.md) | Gate definito |
| GS-REP-009 | [Bootstrap del repository GitHub privato](09-bootstrap-github.md) | Pronto per esecuzione |

## Stato della baseline

Sono presenti policy, modelli di issue e pull request, catalogo etichette, configurazione dichiarativa, profili ruleset, Dependabot per GitHub Actions, quality gate locale, CI su Apple Silicon e procedure idempotenti di applicazione e audit. Non sono stati creati un repository remoto, regole server-side, segreti, certificati o workflow di rilascio: richiedono identità e autorizzazioni esplicite.

`CODEOWNERS` non è attivato finché non esiste un handle o team GitHub verificato. Il template e il generatore sono pronti; inserire un proprietario fittizio produrrebbe una protezione solo apparente.
