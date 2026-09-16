<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Registro delle modifiche

Le modifiche rilevanti per utenti, formati, compatibilità, sicurezza e operazioni vengono raccolte qui. Il progetto segue il versionamento semantico quando esisterà un contratto pubblico stabile; prima di `1.0.0`, ogni incompatibilità deve essere esplicita.

## Non rilasciato

### Aggiunto

- Matrice sparsa Kit, unità di carattere e identificatori MSTTR/MATTR in UI
  (GS-VER-069).
- Richiesta export scientifica e progresso Query nel percorso Must
  (GS-VER-068).
- Metadati scientifici corpus e keyness (digest, contratti, frequenze) in UI
  (GS-VER-067).
- Coordinate query, lineage Evidence e metadati indagine in UI (GS-VER-066).
- Provenienza fonti (digest/byte/ID) e fallimenti strutturati in UI
  (GS-VER-065).
- Catalogo capability, scope, dipendenze e backend del piano in UI
  (GS-VER-064).
- Stato terminale, progresso dettagliato e nodi di analisi dell'esecuzione in UI
  (GS-VER-063).
- Digest QueryAST, generazione e fonti corrispondenti in UI query
  (GS-VER-062).
- CollectionPlanningProfile, step/decisioni del piano e Artifact piano in
  esecuzione (GS-VER-061).
- Caveat strutturati (causa/conseguenza/azione) e Artifact piano in UI
  (GS-VER-060).
- Proposizione Finding tipizzata e formati export Must in UI (GS-VER-059).
- Ruolo/regione/range delle SourceReference Evidence in UI (GS-VER-058).
- Checklist candidatura G3 funzionale e limiti ambiente (GS-VER-057).
- Lineage Evidence, uncertainty/effect size e Caveat tipizzati in UI
  (GS-VER-056).
- Dettaglio `insufficientEvidence` e methodIdentifiers Evidence in UI
  (GS-VER-055).
- Navigazione Overview→sezioni Must e severità Caveat in UI (GS-VER-054).
- Definition of Ready operativa (scheda, template PR, check-docs) e CMP-014
  `implemented` (GS-VER-053).
- Confini App→Kit→Core e CMP-001 `implemented` (GS-VER-052).
- ValidationManifest `analysis-execution-v1`, catalogo a otto manifest Must e
  CMP-010 `implemented` (GS-VER-051).
- Artifact di esecuzione, metadati interpretazione e dimensioni assessment in UI
  (GS-VER-050).
- Salto Evidence→fonte in UI Must e ValidationManifest
  `investigation-history-v1` (GS-VER-049).
- ValidationManifest `interpretation-mvp-v1` e catalogo a sei manifest Must
  (GS-VER-048).
- Misure Evidence tipizzate, Artifact keyness e aggiornamento CMP-012 alle
  superfici UI Must (GS-VER-047).
- Progresso percorso Must in Overview, n-grammi/Artifact corpus, revisione
  report in export e a11y strutturale delle nuove azioni (GS-VER-046).
- Trasparenza UI di ranking Findings, policy di supporto e diversità lessicale
  del corpus (GS-VER-045).
- Confronto keyness diretto in UI Must per `compare.objects` (GS-VER-044).
- Analisi corpus diretta in UI Must, ValidationManifest `planner-mvp-v1` e
  catalogo a cinque manifest Must (GS-VER-043).
- ValidationManifest export, storia eventi indagine in UI, stati piano
  localizzati e CMP-012 `implemented` (GS-VER-042); G3 candidato funzionale.
- ValidationManifest `glifi-query-v1`, progresso import multiplo e anteprima
  Markdown dell'export (GS-VER-041).
- DocumentGroup SwiftUI per `.glifi` con UTType `studio.glifi.project`, Info.plist
  document types e bookmark app-scope (GS-VER-040).
- Salto KWIC→fonte via `sourceText` Kit, teste di indagine multiple, cancellazione
  esecuzione e import multiplo nella UI Must (GS-VER-039).
- Selezione editoriale dei findings e riapertura dell'ultimo progetto `.glifi` nella
  UI Must condivisa; deroga GS-WVR-004 / evidenza GS-VER-038 per CI bloccata dal
  budget Actions sulla PR #7.
- Percorso produttivo 0.1: G1 leggero (ADR-0002 accettato, roadmap attiva),
  vertical slice UI Must su GlifiKit (progetto, import, indagine, piano/esecuzione,
  KWIC, findings, export), corpus gold token V0, ValidationManifest V0–V4 per
  profilo corpus e keyness, checklist G4 a11y e runbook App Store unlisted.
- Evidenze GS-VER-034…037 e aggiornamento CMP-016/CMP-017 a `implemented`.

- Loop di qualità locale `make format` / `make lint` / `make quality-static` /
  `make quality` con controllo dialettale `check-swift-dialect`, job CI
  `static-quality` (Ubuntu), `format-check` e `verify` (Xcode 27), più cache SPM
  anche su `app-store-baseline`; autorità stilistica Apple `swift-format`
  (ADR-0020, GS-DEV-002).
- Primo percorso funzionale condiviso: import TXT UTF-8 bounded, digest SHA-256,
  tokenizzazione italiana con offset, profilo e frequenze su macOS e iPadOS.
- Identificatori opachi e tipizzati, tassonomia di failure eseguibile e
  sostituibilità del tokenizer nel motore headless.
- Output JSON v1 di `GlifiCLI status` e contract check nel quality gate.
- Package `.glifi` v1 con manifest commit point, SQLite di sistema, oggetti fonte
  SHA-256 immutabili, verifica di integrità e fault injection generazionale.
- `GlifiStudioProjectSession` actor-isolated e comandi CLI `project
  create|info|validate`/`import` con envelope e codici di uscita v1.
- `QueryAST v1` canonico, parser `glifi-query-v1` bounded, query per forma/frase,
  booleani, prossimità e regex NFA senza backtracking sul corpus TXT incorporato.
- Concordanze KWIC con SourceRevision, offset UTF-8, contesto configurabile,
  troncatura esplicita e comando CLI `query --text` testuale/JSON v1.
- Estrazione Markdown `md-extract-v1` non eseguibile con `SpanMap` totale da
  `extractedUTF8` a `sourceBytes`, entità derivazionali e budget anti-lookahead.
- Importazione, profilo e query Markdown condivisi da app, GlifiKit e GlifiCLI;
  le righe KWIC JSON espongono coordinate estratte e intervalli sorgente.
- Profilo corpus `corpus-profile-it-v1` bounded e riproducibile con conteggi,
  frequenze, document frequency/range, GriesDP-v1, n-grammi, TTR/MSTTR/MATTR e
  matrice documento-termine sparsa con TF-raw/IDF-smooth/TFIDF versionati.
- Operazione `analyzeCorpus` in GlifiCore/GlifiKit, comando CLI `analyze` con
  JSON v1 completo, signpost locale allowlist e reference test indipendente.
- Keyness `keyness-gtest-ha-bh-v1` tra gruppi espliciti con G-test, p-value χ²,
  odds/log ratio Haldane–Anscombe, correzione Benjamini–Hochberg, diagnostica dei
  conteggi attesi, digest, limiti e fixture indipendente.
- Operazione `compareKeyness`, identificatori revisioni nello snapshot pubblico e
  comando CLI `keyness` testuale/JSON v1 con contract smoke end-to-end.
- `AnalysisDescriptor` v1 canonico con algebra di parametri tagged,
  `AnalysisNodeID`/`ArtifactID` SHA-256 tipizzati e decodifica fail-closed.
- Analysis DAG bounded con deduplica, verifica di cicli/dipendenze/schema, ordine
  topologico, sottografo minimo, invalidazione transitiva e riuso selettivo.
- Persistenza transazionale di descriptor, DAG e Artifact content-addressed nella
  generazione `.glifi`, con commit idempotente, verifica fail-closed, invalidazione
  dei discendenti e fault injection sugli stessi sei checkpoint del manifest.
- Payload analitici tipizzati e versionati per profilo corpus e keyness, con
  descriptor pianificato prima del calcolo, dipendenze esplicite, commit automatico
  e riuso senza tokenizzazione anche dopo la riapertura del progetto.
- Risultati Core, GlifiKit e GlifiCLI con generazione sorgente, generazione
  committata, `ArtifactID` e `AnalysisNodeID` per un lineage verificabile.
- `planner-mvp-v1` deterministico con tassonomia completa delle intenzioni,
  catalogo versionato per profilo corpus/keyness, CollectionPlanningProfile,
  budget, dipendenze, caveat, esclusioni, fallback espliciti e piano persistito.
- Operazione `planAnalysis` in GlifiCore/GlifiKit e comando CLI `plan --request`
  con richiesta JSON bounded, output v1 e riuso dopo riapertura.
- Esecutore del piano con admission energetica/termica, verifica del DAG, Artifact
  durevoli in ordine canonico, riuso idempotente e failure fail-closed.
- Stream GlifiKit bounded posseduto dalla `ProjectSession`, progresso monotono,
  cancellazione cooperativa e comando CLI `execute --request` con `--no-progress`.
- Modello `Evidence`/`Finding`/`Caveat` tipizzato e content-addressed con categorie
  epistemiche, SourceReference esatte, misure tagged e payload fail-closed.
- `interpretation-rules-mvp-v1` per profilo corpus e keyness, con SupportPolicy
  specifiche, `editorial-rank-v1`, soppressioni bounded e `insufficientEvidence`
  senza conclusioni o dati inventati.
- Artifact di interpretazione persistito nel DAG e riusato idempotentemente;
  proiezione completa in GlifiKit e JSON CLI con chiavi localizzabili.
- `InvestigationID` e `InvestigationEventID` tipizzati, eventi cognitivi canonici
  `created`/`editorialSelectionChanged` e replay append-only ramificabile.
- Radice InvestigationHistory distinta dagli Artifact nel package `.glifi` schema
  3, conservata su nuova importazione e verificata fail-closed alla riapertura.
- Migrazione additiva manifest/SQLite schema 2→3 e comandi CLI
  `investigation create|select|list` con request JSON bounded.
- ADR-0021 e GS-VER-031 per separazione tra contenuto autorevole dell'indagine e
  output analitici ricostruibili.
- `ReportRevisionID` e `ReportRevision` content-addressed derivati da un head
  Investigation, limitati ai Finding selezionati e alla chiusura delle Evidence.
- `ExportManifest` v1 con corpus, descriptor, backend, determinismo, selezione,
  file, lineage, Caveat e validazione; export JSON/Markdown in staging verificato.
- Operazione export in GlifiCore/GlifiKit e comando CLI `export --request --output`,
  con digest, receipt, tamper detection e tre checkpoint di interruzione pre-commit.
- ADR-0022 e GS-VER-032 per il confine transazionale e privacy-safe dell'export.
- Renderer Apple-native PDF/A-2u con Core Graphics/Core Text, testo ricercabile,
  struttura taggata, paginazione bounded e verifica strutturale.
- Export RFC 4180 `findings.csv`/`evidence.csv` con payload canonici, relazioni,
  protezione formula-like e confronto con la ReportRevision JSON.
- ADR-0023 e GS-VER-033 per i formati PDF/CSV verificabili e interoperabili.
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
- `actions/cache` aggiornato alla 6.1.0 con SHA immutabile e runtime Node 24.
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

- Gate architetturale e smoke del progresso CLI portabili sui runner Xcode privi
  di `ripgrep`, con fallback `grep` fail-closed.

### Sicurezza

- Controllo locale di credenziali, materiale di firma e riferimenti immutabili delle azioni CI.

## Politica di compilazione

Le sezioni vuote vengono rimosse al rilascio. Ogni voce descrive l'effetto osservabile e collega, quando applicabile, issue, requisito, ADR, migrazione o advisory senza esporre dettagli riservati.
