<!-- SPDX-License-Identifier: BSD-3-Clause -->

# ADR-0030 — Corpus gold italiano di provenienza esterna

| Campo | Valore |
| --- | --- |
| Identificatore | GS-ADR-0030 |
| Versione | 0.1.0 |
| Stato | Proposto |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-20 |
| Decisore | Iniziatore del progetto |
| Data proposta | 2026-09-20 |
| Data decisione | — |
| Approvazione | Direzione scelta (DA-008); resta da scegliere il corpus e autorizzarne l'acquisizione |
| Integra | GS-MET-001-18, GS-LNG-001, GS-VAL-001, ADR-0004 |
| Sostituisce | Nessuno |

## Contesto

Il corpus gold italiano è oggi `it-gold-v0`: **quattro casi sintetici scritti dal progetto**, di
circa quattro parole l'uno, revisionati solo per gli offset UTF-8. Su questa base non si può
misurare nulla: precision, recall e F1 sui confini di token e frase, che GS-MET-001-18 prescrive,
sarebbero calcolati su frasi costruite apposta per passare.

L'iniziatore ha scelto di adottare un corpus di provenienza esterna come gold. Restano due
questioni che la scelta non risolve: **quale** corpus e **a quali condizioni di licenza**, perché
il progetto redistribuisce le proprie fixture in un repository BSD-3-Clause e distribuisce
un'applicazione su App Store.

## Criteri di ammissibilità

Un corpus è ammissibile se soddisfa tutti questi criteri:

1. lingua italiana contemporanea, registro non limitato a un dominio tecnico;
2. licenza che consenta **sia** la redistribuzione dentro un repository BSD-3-Clause **sia** l'uso
   in un prodotto distribuito commercialmente; in alternativa, una modalità di solo riferimento in
   cui il corpus non entra nel repository;
3. provenienza e licenza verificabili alla fonte, non dedotte;
4. nessun dato personale e nessun contenuto che il progetto non possa conservare;
5. annotazione dei confini di token e frase come intervalli UTF-8, o testo su cui il progetto può
   produrre quell'annotazione;
6. dimensione utile a uno split: almeno alcune migliaia di token annotati, separati fra
   validazione e test, senza sovrapposizioni.

## Opzioni

1. **Treebank Universal Dependencies italiano** (per esempio ISDT, VIT, ParTUT): annotazione già
   pronta e riconosciuta dalla comunità. Le licenze dichiarate da questi treebank sono però, nella
   maggior parte dei casi, `CC BY-NC-SA`: la clausola non commerciale è incompatibile sia con la
   redistribuzione in questo repository sia con la distribuzione del prodotto. Resterebbe
   praticabile solo come riferimento non redistribuito, e **la licenza va verificata alla fonte
   prima di qualunque acquisizione**, non data per nota.
2. **Testo italiano redistribuibile annotato dal progetto** (pubblico dominio o `CC BY-SA`):
   il testo è reale e verificabile, l'annotazione dei confini la produce e revisiona il progetto.
   Il gold misurerebbe il tokenizzatore su lingua vera invece che su frasi inventate, restando
   redistribuibile. Costo: l'annotazione va fatta e revisionata a mano.
3. **Testo istituzionale con politica di riuso esplicita** (documenti pubblici con licenza di
   riuso dichiarata): redistribuibile, ma registro formale e poco rappresentativo della lingua
   comune; utile come secondo dominio, non come gold unico.

## Decisione proposta

Opzione 2 come gold redistribuibile del progetto, con l'opzione 1 eventualmente aggiunta come
riferimento esterno non redistribuito se e solo se la verifica di licenza alla fonte lo consente.

Le soglie non vengono inventate: si misura prima P/R/F1 sui confini sul nuovo gold, si registra il
valore osservato come linea di base nell'evidenza e da quel momento una regressione sotto la
linea di base fa fallire il gate. Le soglie assolute di accettazione restano per G4.

## Conseguenze

Il gate acquisisce una misura vera della tokenizzazione italiana e `it-gold-v0` viene sostituito,
non cancellato: resta come regressione di casi limite. Serve un'acquisizione di materiale esterno,
che richiede un'autorizzazione esplicita dell'iniziatore per la fonte scelta.

## Stato

In attesa della scelta del corpus e dell'autorizzazione all'acquisizione: nessun download prima
dell'accettazione.
