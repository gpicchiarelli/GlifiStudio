# 10. Architettura e design

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-10 |
| Tipo | Capitolo normativo |
| Versione | 0.2.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

## 10.1 Descrizione architetturale

La descrizione **DEVE** identificare entità di interesse, finalità, stakeholder, concern, viewpoint, view, model, corrispondenze, decisioni e rationale. Ogni view **DEVE** dichiarare quali concern tratta.

## 10.2 Decisioni architetturali

Un ADR è obbligatorio quando una scelta:

- modifica confini o dipendenze tra moduli;
- introduce o sostituisce persistenza, formato, protocollo o dipendenza principale;
- influenza sicurezza, privacy, compatibilità o migrazione;
- impone un vincolo difficilmente reversibile;
- sceglie un compromesso rilevante fra qualità concorrenti.

Un ADR **DEVE** riportare stato, contesto, decisione, alternative, conseguenze, decisore e collegamenti. Un ADR accettato non viene riscritto per cambiare la storia: viene sostituito da un nuovo ADR.

## 10.3 Invarianti Glifi Studio

- Glifi Studio è il prodotto interattivo; GlifiCore è il motore.
- GlifiCore **NON DEVE** importare SwiftUI, AppKit o UIKit.
- Le dipendenze tra moduli **DEVONO** essere acicliche.
- Il dominio **NON DEVE** essere modellato sulla struttura di un database specifico.
- La visualizzazione **NON DEVE** determinare il formato dei risultati analitici.
- Nessun algoritmo fondamentale **DEVE** richiedere l'intero corpus in memoria.
- L'ottimizzazione **DEVE** seguire una baseline corretta e una misura riproducibile.
- Ogni dipendenza da acceleratori o modelli di sistema **DEVE** avere rilevamento delle capacità e fallback esplicito.
- Risultati probabilistici o generativi **NON DEVONO** sostituire implicitamente fonti o risultati deterministici.

## 10.4 API e confini

Le API pubbliche **DEVONO** essere minime, documentate e orientate al dominio. Tipi interni **NON DEVONO** diventare pubblici per aggirare un confine architetturale. Dipendenze verso framework e servizi sostituibili **DEVONO** attraversare contratti espliciti.

I backend Apple sono governati da [ADR-0008](../adr/0008-portafoglio-tecnologico-apple-silicon.md) e dal [profilo tecnologico Apple](../apple/README.md).
