<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Registro delle modifiche

Le modifiche rilevanti per utenti, formati, compatibilità, sicurezza e operazioni vengono raccolte qui. Il progetto segue il versionamento semantico quando esisterà un contratto pubblico stabile; prima di `1.0.0`, ogni incompatibilità deve essere esplicita.

## Non rilasciato

### Aggiunto

- Baseline Xcode 27 per app native macOS e iPadOS.
- Package condiviso `GlifiCore`, libreria `GlifiKit` e smoke test headless `GlifiCLI`.
- Standard di progetto, documentazione controllata e portafoglio tecnologico Apple.
- Governo del repository privato, modelli di collaborazione, CI e controlli locali.

### Modificato

- Configurazione Dependabot con etichette controllate e aggiornamenti GitHub Actions raggruppati.
- `actions/checkout` aggiornato dalla versione 5.1.0 alla 7.0.1 con SHA immutabile.

### Corretto

- Nessuna correzione rilasciata.

### Sicurezza

- Controllo locale di credenziali, materiale di firma e riferimenti immutabili delle azioni CI.

## Politica di compilazione

Le sezioni vuote vengono rimosse al rilascio. Ogni voce descrive l'effetto osservabile e collega, quando applicabile, issue, requisito, ADR, migrazione o advisory senza esporre dettagli riservati.
