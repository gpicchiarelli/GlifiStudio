# Rilascio e monitoraggio

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AS-009 |
| Tipo | Piano operativo di rilascio |
| Versione | 1.0.0 |
| Stato | Pianificato |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Rilascio

La pubblicazione è manuale. Dopo App Review e approvazione `unlisted`, il
responsabile verifica in una regione pilota pagina prodotto, installazione, primo
avvio, link privacy/supporto e flussi principali. Solo allora il collegamento viene
condiviso attraverso il canale autorizzato.

Il piano di rollback considera che una versione App Store non può essere rimossa
dai dispositivi già installati: si può sospendere la distribuzione, comunicare una
mitigazione e preparare una nuova build. Migrazioni dati devono essere compatibili o
avere una procedura di recupero testata.

## Monitoraggio

Sorvegliare crash, hang, feedback, recensioni eventualmente presenti, metriche
privacy-safe approvate e ticket di supporto. Definire turnazione, severità, tempi di
risposta e criteri di hotfix prima del rilascio. Il link non in elenco deve essere
trattato come distribuibile, non come segreto revocabile.
