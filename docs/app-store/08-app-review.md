# Preparazione di App Review

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AS-008 |
| Tipo | Procedura di submission |
| Versione | 1.0.0 |
| Stato | Pianificato |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Pacchetto per la revisione

App Review deve ricevere una build completa, stabile e con backend attivi. Le
informazioni di contatto devono raggiungere una persona capace di rispondere. Le
note spiegano in modo riproducibile ingresso, dati dimostrativi, flussi non ovvi,
uso dei file, hardware richiesto e ragione della distribuzione non in elenco.

Se esiste autenticazione, Apple riceve un account dimostrativo funzionante o una
modalità demo completa; autenticazione a più fattori, scadenze e regioni non devono
bloccare la verifica. Se non esiste login, il file di revisione deve continuare a
dichiararlo esplicitamente.

## Preflight

- aprire la build installata dall'archivio e ripetere tutti i flussi `Must`;
- verificare link privacy/supporto, metadati, screenshot, rating e diritti;
- verificare acquisti, account, rete e contenuti remoti se introdotti;
- rimuovere placeholder, menu vuoti, testi di debug e funzioni nascoste;
- comunicare le sole limitazioni deliberate, non difetti bloccanti;
- indicare che si richiederà distribuzione non in elenco.

## Riferimento

[Apple — App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
