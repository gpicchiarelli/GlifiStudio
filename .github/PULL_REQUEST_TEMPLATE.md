<!-- SPDX-License-Identifier: BSD-3-Clause -->

## Risultato

Descrivere il comportamento ottenuto e il motivo della modifica.

## Tracciabilità

- Issue:
- Requisiti o criteri di accettazione:
- ADR o decisioni aperte:

## Verifica

- [ ] `make verify` supera tutti i controlli.
- [ ] `make verify-app-store` supera il preflight se la modifica interessa app, packaging, privacy, metadati o distribuzione.
- [ ] `make app-store-submission-check` è stato riesaminato senza falsificare i gate esterni, se pertinente.
- [ ] Ho aggiunto o aggiornato i test pertinenti.
- [ ] Ho eseguito benchmark se cambia un hot path o l'uso delle risorse.
- [ ] Ho verificato migrazione e compatibilità se cambia un formato persistente.

## Impatto

- [ ] Architettura e dipendenze sono coerenti con gli ADR.
- [ ] Sicurezza, privacy, logging ed eventuali entitlement sono stati valutati.
- [ ] Non sono presenti segreti, dati personali, corpus reali o materiale non autorizzato.
- [ ] Interfaccia, accessibilità, italiano iniziale e internazionalizzazione sono stati verificati.
- [ ] Documentazione, tracciabilità e registro modifiche sono aggiornati.

## Rischio e recupero

Descrivere rischio residuo, osservabilità, strategia di rollback e qualunque deroga applicabile. Scrivere `Non applicabile` con motivazione quando la modifica è priva di effetti operativi.
