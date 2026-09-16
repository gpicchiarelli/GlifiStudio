<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Analisi temporale e principio metadata-first

| Campo | Valore |
| --- | --- |
| Identificatore | GS-MET-001-17 |
| Tipo | Specifica normativa dei metodi analitici |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline da revisionare |
| Documento padre | [GS-MET-001](README.md) |

## Metadati come dimensioni analitiche

Autore, anno, categoria, provenienza e campi utente non sono soltanto filtri: possono
definire unità, strati, gruppi, assi di matrice e popolazioni di confronto. Ogni
campo **DEVE** avere identità, tipo (`nominale`, `ordinale`, `quantitativo`,
`temporale`, `testo libero`), cardinalità, dominio, unità, provenienza e politica dei
mancanti. Un testo libero **NON DEVE** diventare categoria senza trasformazione
esplicita.

Raggruppamenti derivati conservano espressione, versione dello schema, ordine delle
categorie, appartenenze multiple e unità escluse. La modifica di un metadato invalida
soltanto i discendenti del DAG che lo usano.

## Semantica temporale

Un valore temporale **DEVE** distinguere istante, data civile, intervallo o periodo
incerto. Precisione, calendario, fuso orario e sorgente sono obbligatori quando
applicabili. L'anno bibliografico non deve essere convertito implicitamente in un
istante.

La discretizzazione dichiara:

- origine e ampiezza degli intervalli;
- calendario/fuso e bordi chiusi o aperti;
- finestre fisse, mobili, cumulative o event-based;
- assegnazione di intervalli o documenti con più date;
- politica per date mancanti, incerte o fuori dominio;
- denominatore per frequenze relative e correzione per esposizione.

## Analisi

Frequenze, tassi, dispersione, diversità, keyness, associazioni e rappresentazioni
possono essere calcolate per intervallo come serie di artefatti comparabili. Una
variazione deve distinguere differenza assoluta, relativa, log ratio, trend stimato e
test inferenziale. Composizione mutevole del corpus e differenti quantità di testo
**DEVONO** essere visibili; un aumento dei conteggi grezzi non è automaticamente un
trend lessicale.

Il documento senza data è escluso, assegnato a una categoria `mancante` o imputato
soltanto secondo una policy persistita. L'imputazione produce un artefatto stimato e
non sovrascrive il metadato osservato.

## Verifica

Fixture coprono anni bisestili, cambi di fuso/ora legale quando applicabili, bordi,
precisioni diverse, intervalli sovrapposti e mancanti. Si verificano partizioni,
denominatori, invariance dell'ordine di importazione, lineage del punto temporale e
invalidazione selettiva dopo una modifica di metadato.
