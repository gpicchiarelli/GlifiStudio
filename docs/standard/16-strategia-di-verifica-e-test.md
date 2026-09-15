# 16. Strategia di verifica e test

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-16 |
| Tipo | Capitolo normativo |
| Versione | 0.2.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

## 16.1 Livelli

| Livello | Oggetto |
| --- | --- |
| Unit test | Tipi, invarianti, algoritmi e casi limite isolati |
| Property test | Proprietà generali di codec, offset, indici e trasformazioni |
| Integration test | Confini tra importer, pipeline, persistenza, ricerca e framework |
| System test | Flussi completi su progetti e corpus di riferimento |
| Numerical reference test | Confronto con risultati scientifici approvati |
| Migration test | Lettura e trasformazione di ogni versione supportata |
| Robustness/fuzz test | Parser, formati binari, query e input ostili |
| UI/accessibility test | Flussi critici, tastiera e semantica accessibile |
| Benchmark | Throughput, latenza, memoria e I/O |

## 16.2 Regole

- Ogni requisito approvato **DEVE** avere almeno una verifica tracciata.
- Ogni correzione di difetto **DEVE** includere un test che fallisce senza la correzione, quando tecnicamente possibile.
- I test **DEVONO** essere deterministici oppure dichiarare e controllare la fonte di variabilità.
- Test che dipendono da rete, locale, fuso orario, clock o ordine di esecuzione **DEVONO** isolare tale dipendenza.
- Fixture e dataset di riferimento **DEVONO** essere versionati, descritti e legalmente utilizzabili.
- Test disabilitati o quarantinati **DEVONO** avere responsabile, motivazione e scadenza.
- La sola percentuale di coverage **NON DEVE** essere usata come prova di correttezza.

## 16.3 Copertura minima sostanziale

Devono essere coperti almeno:

- percorso nominale e casi limite di ogni API pubblica;
- categorie di errore dichiarate;
- cancellazione delle operazioni lunghe;
- round-trip delle posizioni verso la fonte;
- confini Unicode e dei chunk;
- compatibilità dei formati persistenti;
- invarianti numeriche e tolleranze;
- input corrotti per ogni parser controllato dal progetto.

Le app **DEVONO** applicare anche il profilo Apple per [test e diagnostica](../apple/07-test-e-diagnostica.md).
