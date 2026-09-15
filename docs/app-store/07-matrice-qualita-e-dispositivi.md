# Matrice di qualità e dispositivi

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AS-007 |
| Tipo | Piano di test di rilascio |
| Versione | 1.0.0 |
| Stato | Pianificato |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Dimensioni della matrice

La matrice definitiva nasce da DA-001 e comprende almeno:

- macOS 27 su Apple silicon minimo supportato e macchina di riferimento ad alte
  prestazioni;
- iPadOS 27 su classe minima supportata e almeno un iPad recente;
- installazione pulita, aggiornamento e migrazione;
- italiano e inglese, Light/Dark, testo grande e destra-sinistra come stress UI;
- touch, tastiera, puntatore, VoiceOver e ridimensionamento finestra applicabili;
- corpus piccolo, medio, limite e input corrotto;
- spazio insufficiente, memoria sotto pressione, cancellazione e ripresa;
- offline e indisponibilità dei servizi per ogni funzione che li usa.

## Qualità richiesta

Prima della submission: unit, integration e UI test verdi; analisi statica senza
warning; zero crash o hang noti nei flussi `Must`; nessuna perdita o corruzione dati;
Instruments su CPU, memoria, energia e I/O; privacy e accessibilità riesaminate;
archivi firmati validati con la toolchain bloccata.

Simulatori e build senza firma costituiscono prove anticipate, non sostituiscono i
dispositivi fisici né la validazione di App Store Connect.
