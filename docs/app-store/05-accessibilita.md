# Accessibilità della build candidata

| Campo | Valore |
| --- | --- |
| Identificatore | GS-AS-005 |
| Tipo | Piano di verifica accessibilità App Store |
| Versione | 1.0.0 |
| Stato | Pianificato |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Criterio

Una caratteristica di accessibilità può essere dichiarata in App Store Connect
soltanto quando tutti i compiti comuni applicabili sono completabili con quella
caratteristica. La valutazione è distinta per macOS e iPadOS e riguarda la build
candidata, non la sola presenza di etichette nel codice.

## Audit minimo

- VoiceOver: ordine, ruoli, nomi, valori, azioni, aggiornamenti e focus;
- Voice Control e Full Keyboard Access: ogni azione principale è raggiungibile;
- Dynamic Type/Larger Text: nessun contenuto essenziale troncato o sovrapposto;
- contrasto, Dark Mode, Differentiate Without Color e Increase Contrast;
- Reduce Motion e Reduce Transparency senza perdita informativa;
- touch target, puntatore, tastiera esterna e orientamenti iPad supportati;
- zoom e ridimensionamento finestre macOS;
- errori, progresso e cancellazione percepibili senza un singolo canale sensoriale.

Accessibility Inspector aiuta l'audit ma non sostituisce prove manuali con
tecnologie assistive e utenti rappresentativi. Gli esiti confluiscono nella
dichiarazione macchina solo dopo approvazione.

## Riferimento

[Apple — Accessibility nutrition labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
