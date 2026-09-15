<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Vocabolario e localizzazione semantica

| Campo | Valore |
| --- | --- |
| Identificatore | GS-UX-001-14 |
| Tipo | Specifica normativa dell'esperienza utente |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Italiano iniziale approvato; microcopy da validare |
| Documento padre | [GS-UX-001](README.md) |

## Semantica prima della frase

Intenzioni, tipi di finding, caveat, azioni, stati e sezioni editoriali hanno
identificatori stabili indipendenti dalla lingua. Il catalogo Xcode contiene le
formulazioni; il modello persistente contiene chiavi e argomenti tipizzati. Una
modifica editoriale non cambia identità né invalida un'analisi.

## Registro terminologico iniziale italiano

| Concetto | Termine preferito nel primo livello | Termine tecnico accessibile |
| --- | --- | --- |
| `Investigation` | indagine | Investigation |
| `CollectionProfile` | profilo della raccolta | CollectionProfile e metriche |
| `Finding` | risultato emerso o conclusione, secondo contesto | Finding e tipo canonico |
| `Evidence` | evidenza | Evidence e artefatto GS-MET |
| `Caveat` | limite o aspetto da interpretare con cautela | Caveat, causa e severità |
| `AnalysisPlan` | piano dell'analisi | AnalysisPlan e descriptor |
| `notApplicable` | non applicabile ai dati disponibili | precondizione non soddisfatta |
| `insufficientEvidence` | i dati non permettono di concludere | regola e dimensioni insufficienti |
| `SourceReference` | fonte o passaggio di origine | ID, versione, coordinate e lineage |

“Conclusione” è ammesso soltanto per un finding sostenuto; non è sinonimo di dato
osservato. “Confidenza” non viene usato come etichetta generica per solidità,
confidence OCR, probabilità di modello e intervallo statistico, che restano concetti
distinti.

## Regole di scrittura

- Il primo livello usa frasi brevi, attive e verificabili.
- Titoli e azioni descrivono domanda o esito, non il nome dell'algoritmo.
- Messaggi di errore dichiarano conseguenza, ambito preservato e recupero possibile.
- “Non lo sappiamo” viene espresso con rispetto e precisione, indicando che cosa
  manca senza attribuire colpa alla persona.
- Quantità, date, intervalli, percentuali, liste e pluralizzazione usano formattatori
  sensibili al locale; i dati delle fonti non vengono tradotti.
- Frasi non vengono costruite concatenando frammenti localizzati.
- Il dettaglio metodologico mantiene nomi scientifici standard e ne offre una
  descrizione localizzata senza rinominarli.

## Contratto dei messaggi deterministici

Una formulazione del motore interpretativo conserva `messageKey`, argomenti
tipizzati, unità, regola e versione. Le traduzioni **DEVONO** preservare soggetto,
direzione, negazione, forza, quantità e caveat. Se una struttura non può essere
espressa correttamente in una lingua, la funzione resta non disponibile in quella
localizzazione anziché usare una frase ambigua.

## Verifica

Italiano e inglese devono essere verificati su pluralizzazione, testo lungo,
VoiceOver, termini scientifici, negazioni e categorie di solidità. Stress test
destra-sinistra verificano layout e ordine, senza dichiarare una lingua tradotta che
non possiede catalogo e revisione. Studi di comprensione validano le formulazioni
italiane iniziali prima di promuoverle a baseline.

## Riferimenti

- [GS-I18N-002](../internazionalizzazione-interfaccia.md)
- [Apple Human Interface Guidelines — Writing](https://developer.apple.com/design/human-interface-guidelines/writing)
- [Apple Human Interface Guidelines — Inclusion](https://developer.apple.com/design/human-interface-guidelines/inclusion)
