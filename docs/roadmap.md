<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Roadmap iniziale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-PLAN-001 |
| Tipo | Piano di validazione e sviluppo |
| Versione | 1.0.0 |
| Stato | Attivo |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-16 |
| Approvazione | Allineata a GS-PROD-001 e allo stato G1/G2 del percorso produttivo 0.1 |
| Riferimento | ISO/IEC/IEEE 15289:2019, profilo tailored |

## Natura del documento

Questa roadmap è subordinata alla baseline
[GS-PROD-001](specifiche-di-design/10-product-baseline-mvp.md). Riduce per primi i
rischi di `.glifi`, SpanMap, QueryAST, Analysis DAG, runtime bounded e navigazione;
le capacità post-MVP non entrano accidentalmente nelle prime fasi.

Stato osservato al 2026-09-16: **Fase 0/G1 formale leggera chiusa**; **Fase 1/G2
headless sostanzialmente realizzata** (evidenze GS-VER-018…033); **Fase 2** è il
focus produttivo (UI Must sul Kit esistente).

## 1. Fase 0 — Decisioni e prove di fattibilità

Obiettivo: rendere misurabili i vincoli prima di stabilizzare l'architettura.

Uscita registrata: gate **G1 leggero** — GS-PROD Must congelati, ADR-0002 accettato,
owner minimi su DOM/DAT/ANA/UI/VAL/PROD, decisioni hardware/benchmark/CODEOWNERS
parcheggiati se non bloccano la UI slice.

## 2. Fase 1 — Vertical slice headless

Obiettivo: dimostrare l'intera catena senza GUI.

```text
TXT/Markdown UTF-8 → `.glifi` → normalizzazione/SpanMap → `it-token-v1`
                  → QueryAST/KWIC → Artifact/Evidence
```

**Stato:** realizzato e verificato localmente (package, import, query, profilo,
keyness, planner, execute, investigation, export via Core/Kit/CLI). Uscita: gate
**G2** architetturale per il percorso headless.

Limiti residui consapevoli: recovery power-loss completa, gold IT formale,
indice inverted streaming e UI nativa.

## 3. Fase 2 — Primo flusso interattivo (focus corrente)

Obiettivo: offrire un percorso utente completo nelle applicazioni native macOS e iPadOS.

Stato 2026-09-16: **candidato funzionale G3** (GS-VER-035…052). Restano aperti
audit dispositivo, studi UX e gate G4/G5.

- creazione e apertura di un progetto `.glifi`;
- importazione TXT/Markdown con avanzamento e errori non distruttivi;
- domanda, intenzione e scope con CollectionProfile e piano `planner-mvp-v1`;
- esecuzione del piano con stati applicabili/`insufficientEvidence`;
- analisi corpus e confronto keyness anche come azioni dirette in UI;
- ricerca QueryAST/KWIC e salto a coordinate di fonte;
- catena Finding → Evidence → Caveat / ranking / supporto con salto alla fonte;
- storia Investigation append-only, selezione editoriale e Report;
- export PDF/Markdown/CSV/JSON con manifest di provenance;
- ValidationManifest V0–V4 per profilo corpus, keyness, query, export, planner,
  interpretazione, storia Investigation ed esecuzione piano;
- parity dello stesso piano via GlifiKit/GlifiCLI;
- rispetto continuo di GS-SEC/GS-API sui confini Kit e CLI.

Uscita: gate **G3** feature-complete 0.1 sul percorso Must.

## 4. Fase 3 — Documenti e corpus ricchi

Obiettivo: estendere acquisizione e analisi preservando la stessa pipeline.
**Fuori dal focus 0.1** fino a G3 stabile: PDF, OCR, formati office, metodi Should.

## 5. Fase 4 — Analisi avanzata

Obiettivo: capacità specialistiche dopo la stabilizzazione dei dati fondamentali.
**Esplicitamente post-MVP:** CA/PCA/topic, embedding, Foundation Models, sync.

## 6. Principio di rilascio

Ogni fase deve lasciare il sistema corretto, misurabile e utilizzabile. I gate G4 e
G5 aggiungono dispositivi fisici, accessibilità, performance, sicurezza, TestFlight,
firma, App Review e approvazione unlisted. Nessuna fase successiva giustifica un
placeholder o una regressione nel percorso Must.
