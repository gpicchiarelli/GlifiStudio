<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Dati, lineage e persistenza

| Campo | Valore |
| --- | --- |
| Identificatore | GS-DAT-001 |
| Tipo | Specifica di design di dati e persistenza |
| Versione | 1.0.0 |
| Stato | Bozza controllata |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Baseline proposta; prototipo e benchmark richiesti al gate G2 |
| Riferimenti | GS-DOM-001; GS-MET-001-01; GS-MET-001-02; ADR-0016 |

## Scopo e invarianti

Questa specifica governa acquisizione, document model, offset, lineage tecnico,
formato `.glifi`, transazioni, integrità e migrazioni. GS-MET governa il significato
degli artefatti; GS-UX governa come il lineage viene compreso.

- La fonte originale è immutabile e non viene mai riscritta.
- Ogni trasformazione produce una rappresentazione identificata da digest,
  versione e parametri.
- Lo stato autorevole sopravvive a crash; cache e indici sono ricostruibili.
- Nessun offset è valido senza spazio di coordinate e revisione di riferimento.
- Una lettura non verificata o un recupero parziale non diventa stato valido.

## Documento `.glifi`

Il progetto è un package documentale con estensione `.glifi`, Uniform Type
Identifier `studio.glifi.project`, conforme a `UTType.package`. Le app usano
l'infrastruttura document-based di SwiftUI, file coordination e scritture fuori dal
Main Actor. Il package ha questa struttura logica versionata:

```text
Project.glifi/
├── manifest.json
├── store/project.sqlite
├── sources/objects/sha256/aa/<digest>
├── representations/objects/sha256/aa/<digest>
├── artifacts/objects/sha256/aa/<digest>
├── history/events-<generation>.jsonl
└── transactions/<transaction-id>/
```

`manifest.json` contiene formato, generazione committata, project ID, digest degli
elementi radice e requisiti minimi del lettore. `project.sqlite` contiene identità,
relazioni, metadati e riferimenti agli oggetti. Gli oggetti grandi sono file
immutabili content-addressed; SQLite non contiene blob massivi.

Le cache ricostruibili, i file temporanei, i thumbnail e gli indici di sistema
vivono nel container dell'app, fuori dal package, sotto una chiave derivata dal
ProjectID e dalla generazione. Non fanno parte del backup scientifico.

## Tecnologie persistenti

- SQLite di sistema, usato tramite un adapter interno controllato, è il deposito
  relazionale canonico della baseline 0.1.
- SwiftData non è il formato canonico: può essere rivalutato per proiezioni locali
  non autorevoli, ma non deve vincolare schema, migrazioni o interoperabilità.
- JSON canonico conforme a RFC 8785 è usato per descriptor e manifesti quando il
  dominio rientra in I-JSON. Decimali scientifici e valori non finiti usano una
  codifica tipizzata propria, mai coercizioni JSON implicite.
- SHA-256 tramite CryptoKit identifica byte e serializzazioni canoniche. L'hashing
  di file grandi è incrementale e non richiede il file in memoria.
- Ogni formato binario dichiara magic, versione, endian, schema, dimensioni,
  checksum e limiti prima dell'allocazione.

## Incorporazione e riferimenti esterni

La modalità predefinita copia i byte nel package e crea una `SourceRevision`
incorporata. La modalità `externalReference` è una scelta avanzata ed esplicita:
conserva bookmark security-scoped, URL di presentazione non autoritativo, identità
file disponibile e digest osservato all'importazione.

All'apertura, una fonte esterna mancante, non autorizzata o con digest diverso
diventa `externalUnavailable` o richiede una nuova `SourceRevision`; non viene
sostituita silenziosamente. Cambiare modalità crea una revisione e non altera la
provenienza degli artefatti esistenti.

## Pipeline di ingestion

```text
selezione → staging → sniffing → limiti → digest → deduplica → acquisizione
          → estrazione → normalizzazione → segmentazione → commit → indicizzazione
```

1. Il formato è validato da Uniform Type Identifier, signature e contenuto; non
   soltanto dall'estensione.
2. Lettura, digest ed estrazione sono streaming con limite di byte, profondità,
   espansione, pagine, oggetti e tempo.
3. TXT e Markdown MVP accettano UTF-8 valido, con o senza BOM. Altre codifiche sono
   rifiutate con diagnosi e opzione futura esplicita; non si indovina in silenzio.
4. Markdown conserva byte originali e produce testo visibile più struttura
   documentale; nessun contenuto eseguibile viene valutato.
5. PDF digitale, PDF misto e OCR sono famiglie distinte. Il loro supporto resta
   post-MVP finché non superano corpus, limiti e metriche GS-VAL.
6. Un digest già noto consente deduplicazione dei byte, mai fusione automatica di
   identità, metadati o documenti.
7. Una reimportazione cambiata crea una nuova SourceRevision e invalida soltanto i
   discendenti; una reimportazione identica può riusare le rappresentazioni.

## Document model

Una `DocumentRevision` contiene una radice ordinata di blocchi tipizzati:
`heading`, `paragraph`, `listItem`, `quote`, `code`, `tableCell`, `pageBreak` e
`unknown`. Ogni blocco ha ID stabile nella revisione, ordine, attributi validati e
uno o più riferimenti alla fonte. La perdita di struttura è registrata come
Caveat di estrazione.

PDF aggiungerà `PageSpace(page, mediaBox, cropBox, rotation, origin)` e regioni in
punti PDF; OCR aggiungerà poligono, orientamento, motore, versione e confidenza.
Coordinate normalizzate o pixel sono sempre derivate e dichiarano la trasformazione.

## Spazi di coordinate e `SpanMap`

Gli intervalli sono half-open `[start, end)`. Gli spazi canonici sono:

| Spazio | Unità | Uso |
| --- | --- | --- |
| `sourceBytes` | byte della SourceRevision | Verifica dei byte originari |
| `extractedUTF8` | byte UTF-8 della rappresentazione estratta | Lineage tecnico canonico |
| `normalizedUTF8` | byte UTF-8 NFC della rappresentazione analitica | Token, ricerca e analisi |
| `pdfPage` | punti PDF con pagina e trasformazione | Evidenza spaziale PDF |
| `ocrRegion` | poligono nel PageSpace | Provenienza OCR |

Gli indici Swift `String.Index`, UTF-16 e grapheme cluster sono proiezioni di UI e
non sono persistiti come autorità. Ogni intervallo porta representation ID e digest.

`SpanMap` è una sequenza ordinata di segmenti che associa un intervallo di output a
zero, uno o più intervalli di input, con classe:

- `exact`: corrispondenza uno-a-uno verificabile;
- `contributive`: più regioni contribuiscono al risultato;
- `synthetic`: output inserito senza byte sorgente;
- `derivational`: relazione dimostrabile ma non selezione esatta.

Normalizzazione Unicode, newline, rimozione markup, dehyphenation e OCR producono
un nuovo SpanMap. La composizione deve preservare tutte le origini; non si
approssima al “testo più vicino”. Un token conserva il proprio span di superficie
e può avere componenti con span distinti.

## Commit, autosave e recovery

Ogni mutazione usa una transazione identificata. Le righe della nuova generazione
sono append-only rispetto a quelle raggiungibili dalla precedente:

1. scrive nuovi oggetti immutabili in `transactions/<id>` e li verifica;
2. promuove gli oggetti content-addressed senza sovrascrivere quelli esistenti;
3. in una transazione SQLite inserisce relazioni, eventi e radici della generazione
   `N+1`, preservando integralmente le righe raggiungibili da `N`;
4. sincronizza database e directory, quindi produce il nuovo manifest;
5. sostituisce atomicamente il solo manifest e rende eliminabile lo staging.

Il manifest è il commit point. All'apertura si usa l'ultima generazione interamente
verificabile; staging incompleti sono ignorati o offerti alla diagnostica. Autosave
coalesca eventi di dominio ma non interrompe importazioni a metà commit. Un
checkpoint analitico non è valido finché descriptor, input e checksum non coincidono.

## Schema e compatibilità

La prima versione è `formatVersion = 1`. Ogni cambio incompatibile incrementa la
major del formato; aggiunte ignorabili incrementano la minor. Il lettore deve:

- leggere e scrivere la versione corrente;
- leggere la precedente major `N-1` quando ne esisterà una e migrarla soltanto su
  copia transazionale con backup recuperabile;
- aprire in sola lettura, oppure rifiutare senza modifiche, una versione futura;
- conservare versioni di algoritmi e findings storici; il ricalcolo è una nuova
  revisione, non una riscrittura della storia;
- non promettere downgrade. L'export interoperabile è la via di uscita supportata.

## Integrità, minacce e limiti

Prima di seguire un path del package si rifiutano assoluti, `..`, symlink,
hard-link inattesi e collisioni Unicode/case. Ogni conteggio è validato prima
dell'allocazione. Package, database e oggetti corrotti aprono in modalità di
recupero senza eseguire query o parser su contenuto non validato.

Il controllo integrità verifica manifest, schema, foreign key, digest, oggetti
mancanti e raggiungibilità. La riparazione non inventa dati: può ricostruire cache,
isolare oggetti corrotti, recuperare una generazione precedente e produrre un
rapporto locale privo di contenuto del corpus.

## Export e assenza di lock-in

Ogni export è `humanReadable` o `machineReadable`. Il primo privilegia PDF/Markdown;
il secondo usa UTF-8 CSV/TSV e JSON documentato. Matrici e grafi possono avere
formati sparsi dichiarati. Ogni export scientifico include o affianca un
`ExportManifest` con ProjectID pseudonimizzabile, corpus/versioni, descriptor,
digest, software, data, locale e Caveat. Nessun export contiene fonti complete per
default se la selezione non lo richiede esplicitamente.

## Criteri di conformità

- round-trip del package e migrazione con kill injection a ogni commit point;
- test Unicode su ogni trasformazione e composizione SpanMap;
- fuzzing di manifest, package, Markdown e futuri parser PDF/OCR;
- apertura sicura di oggetti mancanti, corrotti, futuri e riferimenti esterni;
- identità di risultato tra esecuzione in-memory, streaming e riaperta;
- nessun blob massivo nel database e nessuna lettura integrale obbligatoria.

## Riferimenti tecnici

- [Unicode Normalization Forms, UAX #15](https://www.unicode.org/reports/tr15/)
- [Unicode Text Segmentation, UAX #29](https://www.unicode.org/reports/tr29/)
- [RFC 8785 — JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html)
- [CryptoKit SHA256](https://developer.apple.com/documentation/cryptokit/sha256)
- [SwiftUI FileDocument](https://developer.apple.com/documentation/swiftui/filedocument)
