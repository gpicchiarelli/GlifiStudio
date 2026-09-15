# Accessibilità

| Campo | Valore |
| --- | --- |
| Identificatore | GS-APL-003 |
| Tipo | Standard applicativo Apple |
| Versione | 0.1.0 |
| Stato | Approvato |
| Responsabile | Iniziatore del progetto |
| Ultima modifica | 2026-09-15 |
| Approvazione | ADR-0006 |

## Regole

- Controlli SwiftUI standard **DEVONO** essere preferiti per conservarne la semantica nativa.
- Ogni controllo o contenuto essenziale **DEVE** avere nome, ruolo, valore e azioni comprensibili con VoiceOver.
- Il percorso `Must` **DEVE** essere utilizzabile da tastiera e con Full Keyboard Access.
- Testo e layout **DEVONO** adattarsi alle dimensioni di testo supportate senza perdita di contenuto essenziale.
- Colore, forma, posizione, suono o animazione **NON DEVONO** essere l'unico mezzo per comunicare uno stato.
- Reduce Motion, Increase Contrast e Differentiate Without Color **DEVONO** essere rispettati quando pertinenti.
- Controlli personalizzati **DEVONO** essere verificati con Accessibility Inspector prima dell'integrazione.
- Ogni rilascio **DEVE** includere un audit dei flussi principali e una verifica manuale VoiceOver.

Riferimenti: [Accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility) e [Accessibility Inspector](https://developer.apple.com/documentation/accessibility/accessibility-inspector).
