# 11. Dati, testo e persistenza

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-11 |
| Tipo | Capitolo normativo |
| Versione | 0.1.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

## 11.1 Fonte e lineage

- La fonte originale **NON DEVE** essere modificata implicitamente.
- Ogni artefatto derivato **DEVE** identificare input, trasformazione, versione e parametri.
- Un risultato **DEVE** poter essere ricondotto al corpus e alla fonte applicabili.
- Testo digitale e testo OCR **DEVONO** essere distinguibili.

## 11.2 Identità

Documenti, corpus, analisi e artefatti persistenti **DEVONO** avere identità logiche stabili. Path, posizione e nome visualizzato **NON DEVONO** costituire l'identità.

Identificatori di domini differenti **DEVONO** essere tipi distinti anche quando condividono la rappresentazione numerica.

## 11.3 Unicode e offset

- Il significato di ogni offset **DEVE** specificare spazio di coordinate e unità.
- Byte, code unit UTF-16, scalar Unicode e grapheme cluster **NON DEVONO** essere trattati come equivalenti.
- Le conversioni di offset **DEVONO** essere testate con testo multilingue, emoji, combinazioni canoniche e input malformato.
- I confini tra chunk **NON DEVONO** cambiare il risultato semantico della decodifica o tokenizzazione.

## 11.4 Elaborazione massiva

- Importazione e trasformazioni fondamentali **DEVONO** supportare elaborazione incrementale.
- Le code tra fasi **DEVONO** avere limiti e backpressure.
- Le strutture massive **NON DEVONO** allocare un oggetto heap o duplicare una stringa per ogni occorrenza senza evidenza che il costo sia accettabile.
- Ogni limite di dimensione **DEVE** essere esplicito, configurabile quando opportuno e verificato prima dell'allocazione.

## 11.5 Persistenza e formati

Ogni formato proprietario persistente **DEVE** essere:

- specificato indipendentemente dall'ABI Swift;
- versionato e identificabile;
- validabile prima dell'uso;
- compatibile con una strategia di migrazione;
- resistente a troncamento, corruzione e valori fuori limite;
- esplicito rispetto a endianness, allineamento e checksum quando applicabili.

Cache ricostruibili e dati autorevoli **DEVONO** essere distinguibili. Una cache corrotta **DOVREBBE** poter essere eliminata e ricostruita senza perdere fonti o configurazioni.

## 11.6 Migrazioni

Ogni modifica incompatibile al formato **DEVE** fornire migrazione, lettura compatibile o rifiuto esplicito e sicuro. Le migrazioni **DEVONO** essere idempotenti dove possibile, testate su fixture versionate e non distruttive prima della verifica del risultato.
