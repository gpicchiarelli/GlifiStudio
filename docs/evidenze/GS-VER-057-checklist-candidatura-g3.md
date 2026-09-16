<!-- SPDX-License-Identifier: BSD-3-Clause -->

# GS-VER-057 — Checklist candidatura G3 funzionale

| Campo | Valore |
| --- | --- |
| Identificatore | GS-VER-057 |
| Tipo | Evidenza di verifica |
| Versione | 1.0.0 |
| Stato | Superato localmente |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-16 |
| Approvazione | Evidenza operativa dell'iniziatore del progetto |
| Riferimenti | GS-PROD-001 G3; GS-DOR-001; GS-VER-035…069 |

## Ambito

Congelare la checklist di candidatura G3 funzionale per il percorso Must 0.1:
cosa è chiuso in codice/documentazione e cosa resta bloccato da ambiente.

## Checklist chiusa (locale)

- [x] Percorso Must UI su GlifiKit (DocumentGroup, import, piano/execute, query,
      Findings/Evidence, indagine, export)
- [x] Azioni dirette `analyzeCorpus` / `compareKeyness`
- [x] Salto KWIC→fonte e Evidence→fonte
- [x] Trasparenza ranking, SupportPolicy, lineage Evidence e proposizione tipizzata
- [x] Trasparenza piano/esecuzione/query/fonti/export e metadati scientifici
      corpus/keyness (GS-VER-060…069)
- [x] ValidationManifest V0–V4 × 8 capability Must
- [x] DoR operativa (GS-DOR-001) e CMP-001/010/012/014 implemented
- [x] `make quality-static` verde sul tip
- [x] Checklist candidatura aggiornata a GS-VER-069

## Aperto (non G3 funzionale)

- [ ] `make verify` / Xcode 27 su runner
- [ ] CI remota (GS-WVR-004 budget Actions)
- [ ] VoiceOver e audit dispositivo (G4 / CMP-019)
- [ ] Kill/power-loss reale (CMP-005/006)
- [ ] Fuzz ostile esteso (CMP-002)
- [ ] Ranking empirico (CMP-018)
- [ ] Hardware baseline (CMP-021)
- [ ] Firma / TestFlight / App Store unlisted (G5)

## Risultato

**Superato** come dichiarazione di candidatura funzionale G3. Non chiude G3
formale né G4/G5.

## Limiti

Budget Actions: GS-WVR-004. Runtime Apple non disponibile in questo ambiente.
