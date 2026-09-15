# 25. Definition of Done

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-25 |
| Tipo | Capitolo normativo |
| Versione | 0.3.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

Una modifica è completa soltanto quando tutti i punti applicabili sono soddisfatti:

- criteri di accettazione verificati;
- requisiti e tracciabilità aggiornati;
- ADR creato o aggiornato quando necessario;
- codice formattato, compilato e revisionato;
- test pertinenti aggiunti e superati;
- errori, cancellazione, sicurezza e privacy valutati;
- benchmark eseguiti se cambia un hot path;
- migrazioni e compatibilità provate se cambiano dati persistenti;
- documentazione ed esempi aggiornati;
- nessun segreto o dato non autorizzato incluso;
- pull request compilata, revisioni bloccanti risolte e proprietà del codice rispettata;
- dipendenze e automazioni nuove motivate, inventariate e fissate in modo riproducibile;
- log e artefatti esaminati per dati sensibili;
- quality gate verdi o deroghe valide;
- evidenza di verifica archiviata;
- variante scientifica, descriptor, determinismo e casi degeneri specificati quando applicabili;
- reference test indipendente e invarianti matematiche superati per ogni metodo modificato;
- lineage e invalidazione del DAG verificati per ogni nuovo artefatto analitico.

Una modifica non è completa se il solo modo di integrarla richiede bypass, credenziali personali, stato locale non versionato o un controllo disabilitato.
