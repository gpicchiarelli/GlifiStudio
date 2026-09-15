<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Registro delle modifiche

Le modifiche rilevanti per utenti, formati, compatibilità, sicurezza e operazioni vengono raccolte qui. Il progetto segue il versionamento semantico quando esisterà un contratto pubblico stabile; prima di `1.0.0`, ogni incompatibilità deve essere esplicita.

## Non rilasciato

### Aggiunto

- Primo percorso funzionale condiviso: import TXT UTF-8 bounded, digest SHA-256,
  tokenizzazione italiana con offset, profilo e frequenze su macOS e iPadOS.
- Identificatori opachi e tipizzati, tassonomia di failure eseguibile e
  sostituibilità del tokenizer nel motore headless.
- Output JSON v1 di `GlifiCLI status` e contract check nel quality gate.
- Package `.glifi` v1 con manifest commit point, SQLite di sistema, oggetti fonte
  SHA-256 immutabili, verifica di integrità e fault injection generazionale.
- `GlifiStudioProjectSession` actor-isolated e comandi CLI `project
  create|info|validate`/`import` con envelope e codici di uscita v1.
- Baseline Xcode 27 per app native macOS e iPadOS.
- Package condiviso `GlifiCore`, libreria `GlifiKit` e smoke test headless `GlifiCLI`.
- Standard di progetto, documentazione controllata e portafoglio tecnologico Apple.
- Governo del repository privato, modelli di collaborazione, CI e controlli locali.
- Specifica normativa GS-MET con 22 contratti matematici, statistici, linguistici e algoritmici.
- `AnalysisDescriptor`, Analysis DAG, classi di determinismo e fondazione concettuale `GlifiMath` tramite ADR-0013.
- Requisiti e verifiche tracciate per metodi analitici, content analysis e visualizzazioni scientifiche.
- Specifica normativa GS-UX con 14 contratti per paradigma d'indagine, intenzioni,
  profilo della raccolta, planner, findings, navigazione, lineage, storia e rapporto.
- Modello concettuale di Project/Corpus/Investigation, motore interpretativo
  deterministico e progressive disclosure Conclusione → Evidenza → Fonti → Metodo.
- ADR-0014, requisiti e verifiche tracciate per esperienza macOS/iPadOS,
  accessibilità, comprensione e localizzazione semantica.
- ADR-0015 e verifica TV-049 per distinguere compilatore Apple Swift 6.4,
  Swift 6 language mode e SwiftPM tools 6.4.
- Famiglia GS-DSG con dieci specifiche implementative per dominio, package `.glifi`
  e lineage, italiano, QueryAST, sistema analitico, runtime, UI, visualizzazioni,
  validazione scientifica e product baseline 0.1.
- ADR-0016 per formato di progetto, store SQLite di sistema, oggetti SHA-256,
  SpanMap, perimetro locale e nucleo analitico del primo prodotto completo.
- ADR-0017 e policy macOS per zero telemetria applicativa, Unified Logging
  centralizzato, signpost tipizzati e Xcode Organizer come canale di campo.
- ADR-0018 e `GlifiRuntimePolicy` per Low Power Mode, termica, pressione memoria,
  lifecycle, QoS, App Nap e parallelismo adattivo coperti da test.
- GS-SEC-001 con asset, trust boundary, minacce THR-001–THR-020, input ostili,
  resource exhaustion, modelli, logging, export e gate di sicurezza.
- GS-API-001 per lifecycle GlifiKit, structured concurrency, progressi,
  cancellazione, failure semantics, CLI, exit status e compatibilità pre-1.0.
- Matrice di conformità machine-readable e `make check-compliance`, con stati
  verificabili e blocchi espliciti per le evidenze ancora mancanti.
- Seed verificabili per otto casi linguistici italiani, quattro riferimenti
  numerici e dieci descrittori avversari safe-by-construction.
- ADR-0019 e Definition of Ready rafforzata per spostare il progetto dalla
  completezza documentale alla prova di implementazione.

### Modificato

- Configurazione Dependabot con etichette controllate e aggiornamenti GitHub Actions raggruppati.
- `actions/checkout` aggiornato dalla versione 5.1.0 alla 7.0.1 con SHA immutabile.
- Quality gate documentale esteso a indicizzazione, copertura e integrazione delle specifiche GS-MET.
- Quality gate documentale esteso alla copertura e integrazione delle specifiche GS-UX.
- Quality gate documentale esteso a presenza, identificatori, copertura e
  integrazione delle dieci specifiche di design.
- Manifest SwiftPM elevato a tools 6.4 e controllo toolchain reso vincolante sulla
  versione minima compatibile, sul language mode e sulla strict concurrency.
- Quality gate Apple esteso per respingere logging libero, output non strutturato,
  rete, MetricKit e SDK di telemetria non autorizzati.
- GS-DAT-001 esteso con commit point formale, recovery per operazione e schema
  riproducibile ExportManifest v1.
- Modello trasversale degli errori esteso con categorie, retry, terminali e stato
  che rimane valido.

### Corretto

- Nessuna correzione rilasciata.

### Sicurezza

- Controllo locale di credenziali, materiale di firma e riferimenti immutabili delle azioni CI.

## Politica di compilazione

Le sezioni vuote vengono rimosse al rilascio. Ogni voce descrive l'effetto osservabile e collega, quando applicabile, issue, requisito, ADR, migrazione o advisory senza esporre dettagli riservati.
