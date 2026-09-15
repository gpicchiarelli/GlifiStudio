# Baseline linguistica italiana

| Campo | Valore |
| --- | --- |
| Identificatore | GS-I18N-001 |
| Tipo | Specifica della configurazione linguistica analitica |
| Versione | 0.2.0 |
| Stato | Bozza controllata |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | Decisione esplicita dell'iniziatore del progetto |
| Decisione | [ADR-0004](adr/0004-italiano-lingua-iniziale.md) |

## Ambito

La baseline analitica iniziale di Glifi Studio è calibrata per la lingua italiana. Questo documento governa la lingua del contenuto analizzato; l'internazionalizzazione dell'interfaccia è disciplinata separatamente da [GS-I18N-002](internazionalizzazione-interfaccia.md).

| Aspetto | Valore iniziale | Identificatore |
| --- | --- | --- |
| Locale predefinito | Italiano, Italia | `it_IT` |
| Lingua predefinita dell'analisi | Italiano | `it` |

## Regole dell'analisi linguistica

- L'italiano è la lingua predefinita quando un progetto non specifica una lingua.
- Tokenizzazione, normalizzazione e segmentazione **NON DEVONO** assumere che ogni testo sia italiano.
- Lingua e versione del backend linguistico **DEVONO** essere registrate negli artefatti derivati.
- Il riconoscimento automatico della lingua, quando introdotto, **NON DEVE** sovrascrivere una scelta esplicita dell'utente.
- Qualità, corpora di riferimento e soglie per lemmi, parti del discorso ed entità restano da approvare tramite DA-008.

## Estensione futura

Nuove lingue analitiche devono usare contratti sostituibili di GlifiCore e fixture specifiche, senza modificare il significato dei risultati già prodotti in italiano.

## Verifica

La baseline richiede un test del default `it`/`it_IT` e, quando saranno disponibili le prime funzioni linguistiche, fixture italiane con corpora, metriche e soglie approvate.
