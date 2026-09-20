<!-- SPDX-License-Identifier: BSD-3-Clause -->

# DoR — Programma di robustezza e contratti trasversali

| Campo | Valore |
| --- | --- |
| Identificatore | GS-DOR-004 |
| Tipo | Scheda Definition of Ready |
| Versione | 1.0.0 |
| Stato | Ready |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-19 |
| Approvazione | Richiesta dell'iniziatore: procedere con le implementazioni senza interruzioni |
| Riferimenti | GS-STD-001-07; RQ-044; RQ-045; RQ-058; GS-SEC-001 THR-001, THR-009; GS-API-001 § 8; GS-VAL-001 |

## Criterio di selezione

Requisiti trasversali ancora in «Baseline definita» o parziali, verificabili interamente nel
repository senza dispositivi, utenti o dati esterni, in ordine di rapporto fra rischio ridotto e
sforzo.

| # | Task | Requisito | Esito atteso |
| --- | --- | --- | --- |
| S1 | Tassonomia delle failure eseguibile | RQ-058 | Tabella di GS-API-001 § 8 in codice, asserita a ogni costruzione di `GlifiFailure`, controllo statico dei siti letterali nel gate |
| S2 | Fuzz deterministico dei parser | RQ-044, THR-001, THR-009 | Generatori con seed per TXT, Markdown e `glifi-query-v1`: nessun crash, esito tipizzato, invarianti di SpanMap e determinismo, tempo limitato |
| S3 | ValidationManifest delle capacità post-0.1 | RQ-045 | Manifest V0–V4 per ponderazione/BM25, MTLD, n-grammi e viste, registrati nel catalogo |

## Scheda Definition of Ready

| Voce | Evidenza | N/A |
| --- | --- | --- |
| outcome e confini | Nessuna nuova capacità di prodotto; solo contratti, verifiche e manifest | — |
| requisiti | RQ-044, RQ-045, RQ-058 | — |
| contratto di dominio/API | Nuovo tipo pubblico `GlifiFailureTaxonomy`; categorie e campi delle failure invariati | — |
| failure semantics | Le failure fuori tabella sono riallineate: la sola differenza osservabile è `retryDisposition`/`retainedState` coerenti con GS-API-001 § 8 | — |
| esperienza prevista | Nessun cambiamento di UI | — |
| verifica | Test Swift, script nel gate, controlli negativi, `make verify` | — |
| dati e migrazione | Nessuna modifica di formato | — |
| sicurezza/privacy | Il fuzz non usa rete né dati reali; seed dichiarati | — |
| prestazioni/sistema | Iterazioni di fuzz limitate per restare entro il tempo del gate | — |
| tracciabilità | Evidenza, requisiti, tracciabilità, matrice e CHANGELOG per ogni task | — |
| decisioni | Nessuna decisione riservata all'iniziatore | — |

## Stato DoR

**Ready** per S1–S3.

## Avanzamento

| # | Stato | Evidenza o motivo |
| --- | --- | --- |
| S1 | Completato | GS-VER-119 |
| S2 | Completato | GS-VER-120 |
| S3 | Completato | GS-VER-121 |
