# Strategia TestFlight

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AS-006 |
| Tipo | Piano di beta test |
| Versione | 1.0.0 |
| Stato | Pianificato |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Stadi

| Stadio | Pubblico | Scopo | Uscita |
| --- | --- | --- | --- |
| Interno | Team nominato | installazione, migrazioni, smoke e crash | zero blocchi P0/P1 |
| Esterno ristretto | Utenti rappresentativi autorizzati | comprensione, accessibilità, corpus reali controllati | flussi `Must` con criteri raggiunti |
| Release candidate | Sottoinsieme stabile | regressione finale su build immutata | firma del gate di submission |

Ogni build è identificata da versione, numero, commit, toolchain e piattaforma. Il
feedback è classificato e collegato a issue; crash, hang, perdita dati, violazioni
privacy e risultati analitici errati impediscono la promozione. Credenziali e dati
personali non entrano nel repository.

TestFlight è una fase di validazione; una build beta non deve essere proposta come
app non in elenco definitiva.
