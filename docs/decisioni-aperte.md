# Decisioni aperte

| Campo | Valore |
| --- | --- |
| Identificatore | GS-ISS-001 |
| Tipo | Registro delle questioni e decisioni aperte |
| Versione | 0.15.0 |
| Stato | Attivo |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non applicabile; registro operativo |
| Riferimento | ISO/IEC/IEEE 15289:2019, profilo tailored |

Questo registro contiene le scelte che incidono sul prodotto o sull'architettura e che gli appunti non risolvono. Quando una decisione viene presa, il suo esito va registrato in un ADR e la voce va chiusa senza cancellarne la storia.

| ID | Tema | Domanda | Evidenza necessaria | Responsabile | Stato |
| --- | --- | --- | --- | --- | --- |
| DA-001 | Matrice piattaforme | Quali classi di capacità, memoria e dispositivi con macOS 27 e iPadOS 27 sono supportate? | Benchmark CPU/GPU/Neural Engine, bacino utenti e costo della matrice di test | Da assegnare | Parzialmente definita: strategia runtime approvata da ADR-0008 |
| DA-002 | MVP | Quali formati, metodi GS-MET e capacità qualitative appartengono al primo rilascio utilizzabile? | Casi d'uso prioritari, dipendenze analitiche e capacità del team | Da assegnare | Aperta; catalogo scientifico ora definito |
| DA-003 | Progetto | Il progetto incorpora le fonti, le referenzia o supporta entrambe le modalità? | Portabilità, sicurezza, duplicazione e gestione file mancanti | Da assegnare | Aperta |
| DA-004 | Persistenza | Quale combinazione usare per metadati, posting list, matrici e cache? | Prototipi e benchmark | Da assegnare | Aperta |
| DA-005 | GlifiStore | Quali requisiti copre il progetto esistente e con quali costi di integrazione? | Valutazione tecnica e prestazionale | Da assegnare | Aperta |
| DA-006 | Offset | Qual è il contratto canonico per collegare byte, testo estratto e posizioni UI? | Prototipi Unicode, PDF e OCR | Da assegnare | Aperta |
| DA-007 | Versionamento | Quali identificatori, digest e formati concreti realizzano versioni, descriptor e Analysis DAG? | Prototipo di serializzazione, invalidazione e migrazione | Da assegnare | Parzialmente definita da ADR-0013, GS-MET-001-01 e GS-MET-001-02 |
| DA-008 | Linguistica | Quali annotazioni italiane e quali lingue successive devono raggiungere quali soglie qualitative? | Corpus gold, split, metriche GS-MET-001-18 e valutazione dei backend | Da assegnare | Parzialmente definita: italiano e protocollo approvati; corpus e soglie aperti |
| DA-009 | PDF/OCR | Quale qualità e quali informazioni spaziali devono essere preservate? | Corpus PDF rappresentativo e metriche OCR | Da assegnare | Aperta |
| DA-010 | Query | Qual è la sintassi pubblica per query testuali, linguistiche e sui metadati? | Prototipi API e UX | Da assegnare | Aperta |
| DA-011 | Benchmark | Quali dataset, soglie, dispositivi e margini promuovono Swift, Accelerate, Core ML o Metal a backend predefinito? | Scenari reali, energia, termica e riproducibilità | Da assegnare | Parzialmente definita: criteri approvati da ADR-0008 |
| DA-012 | Distribuzione | App Store, distribuzione diretta o entrambe? | Sandbox, notarizzazione, plugin/modelli e accesso ai file | Iniziatore del progetto | Chiusa: App Store con distribuzione non in elenco, ADR-0011 |
| DA-013 | Privacy | Quali garanzie esplicite offrire su elaborazione locale, telemetria e dati sensibili? | Posizionamento prodotto e minacce | Da assegnare | Aperta |
| DA-014 | Nome | Il nome Glifi Studio è utilizzabile e registrabile? | Ricerca legale e marchi | Da assegnare | Aperta |
| DA-015 | Governo documentale | Chi approva formalmente le baseline? | Nomina dei ruoli e autorità del progetto | Da assegnare | Parzialmente definita: flusso e responsabilità provvisorie approvati da ADR-0009 |
| DA-016 | Contributi e copyright | Come vengono attestati i diritti sui contributi e chi può autorizzare un futuro cambio di licenza? | Titolarità, modello contributivo, eventuale CLA o DCO | Da assegnare | Aperta |
| DA-017 | Parità e trasferimento | Quali funzioni appartengono a ciascun rilascio e come vengono trasferiti o sincronizzati i progetti? | Flussi prioritari, formato progetto, UX documentale e privacy | Da assegnare | Parzialmente definita: parità semantica approvata da ADR-0014; perimetro e trasferimento aperti |
| DA-018 | Identità e firma | Quali bundle identifier, Apple Developer Team, entitlements e profili di firma sono definitivi? | Titolarità dell'account, modalità di distribuzione e capacità applicative | Da assegnare | Parzialmente definita: bundle multipiattaforma candidato `studio.glifi.GlifiStudio`; team e profili aperti |
| DA-019 | Intelligenza generativa | Quali funzioni assistive usano Foundation Models e con quali policy di modello, contesto, retention e fallback? | Prototipi italiani, valutazione qualità, privacy e disponibilità dispositivi | Da assegnare | Aperta; vincoli generali approvati da ADR-0008 |
| DA-020 | Sincronizzazione Apple | CloudKit, iCloud e Handoff appartengono al prodotto e con quale modello di conflitto e uso offline? | Identità cross-device, privacy, quote, migrazioni e UX | Da assegnare | Aperta |
| DA-021 | Integrazione di sistema | Quali entità e azioni esporre a Spotlight, App Intents, Siri e Shortcuts? | Flussi MVP, autorizzazioni, deep link e minimizzazione dati | Da assegnare | Aperta |
| DA-022 | Hosting GitHub | Quali organizzazione o account, piano e URL ospitano il remote privato? | Titolarità, costi, funzioni di protezione, backup e continuità | Iniziatore del progetto | Chiusa: `gpicchiarelli/GlifiStudio`, privato, profilo `solo`; ADR-0012 |
| DA-023 | Ownership del codice | Quali handle o team sono proprietari dei percorsi sensibili? | Identità GitHub verificate e separazione delle responsabilità | Da assegnare | Aperta; `CODEOWNERS` intenzionalmente non attivo |
| DA-024 | Accesso all'app non in elenco | Il possesso del link è sufficiente o gli utenti devono anche essere autenticati e autorizzati? | Pubblico previsto, dati trattati e modello di supporto | Da assegnare | Aperta; il link App Store non costituisce controllo degli accessi |
| DA-025 | Baseline numerica | Quali dataset, implementazioni indipendenti, tipi floating-point e tolleranze approvano ogni variante GS-MET iniziale? | Review scientifica, fixture pubblicabili e confronto cross-backend | Da assegnare | Aperta; classi e criteri definiti da GS-MET-001-03 |
| DA-026 | Validazione UX | Quali profili utente, compiti, campione e soglie approvano efficacia, efficienza, comprensione e calibrazione? | Ricerca sul campo, protocollo ISO 9241-210 tailored e studi accessibili | Da assegnare | Aperta; dimensioni definite da GS-UX-001-13 |
| DA-027 | Persistenza dell'indagine | Come serializzare storia ramificata, piani, findings, caveat, selezioni editoriali e stato per-scena? | Prototipi, migrazioni, crash recovery, concorrenza multi-finestra e dimensioni reali | Da assegnare | Aperta; semantica definita da GS-UX-001-02 e GS-UX-001-10 |
| DA-028 | Policy del planner | Quali intenzioni, famiglie, budget, regole di ridondanza e stime di costo appartengono al primo planner? | Casi d'uso, corpus, benchmark, decision table e review scientifica | Da assegnare | Aperta; contratto definito da GS-UX-001-04 |
| DA-029 | Solidità dei findings | Quali SupportPolicy e soglie per famiglia consentono strong/moderate/weak/caution/insufficient? | Simulazioni, corpus gold, effect size, stabilità e studi di comprensione | Da assegnare | Aperta; vietato un confidence score universale |
| DA-030 | Relazione ed export | Quali formati, manifesti di lineage, regole editoriali e livelli generativi sono supportati? | Prototipi interoperabili, accessibilità, round-trip e verifica di attribuzione | Da assegnare | Aperta; modello concettuale definito da GS-UX-001-10 |

## Prossime decisioni consigliate

Le prime decisioni da affrontare sono DA-001, DA-002, DA-003, DA-006, DA-007,
DA-008, DA-011, DA-015, DA-023 e DA-025–DA-029. DA-019–DA-021 e DA-030 seguono la stabilizzazione dei contratti
fondamentali: impediscono che AI generativa, sincronizzazione o integrazioni di
sistema diventino dipendenze premature.
