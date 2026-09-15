# 18. Errori, logging e osservabilità

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-18 |
| Tipo | Capitolo normativo |
| Versione | 0.2.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

## 18.1 Errori

Il modello degli errori **DEVE** distinguere almeno:

- input non valido;
- formato non supportato o incompatibile;
- I/O e autorizzazioni;
- dati corrotti o inconsistenti;
- risorsa insufficiente;
- cancellazione;
- condizione recuperabile;
- violazione di invariante interna.

## 18.2 Logging

- Ogni operazione lunga **DEVE** avere un identificatore di correlazione.
- I log **DEVONO** distinguere livelli e categorie.
- Contenuti sensibili **DEVONO** essere redatti o omessi.
- Un log **NON DEVE** essere necessario per determinare programmaticamente l'esito di un'operazione.
- Diagnostica e metriche **DEVONO** avere overhead misurato e configurabile.
- Le app Apple **DEVONO** usare il sistema unified logging tramite `Logger`, con subsystem, categorie e livelli stabili.
- Ogni interpolazione **DEVE** dichiarare una privacy coerente; testo, prompt e path dell'utente restano privati o omessi.
- Le fasi costose **DEVONO** esporre intervalli `OSSignposter` correlabili con operazione, cancellazione e risultato.
- Metriche di produzione **NON DEVONO** introdurre telemetria di terzi senza una decisione privacy esplicita.

## 18.3 Recupero

Interruzione, crash o cancellazione **NON DEVONO** lasciare un progetto apparentemente valido ma semanticamente parziale. Scritture critiche **DEVONO** usare transazioni, file temporanei con sostituzione atomica o un protocollo equivalente documentato.
