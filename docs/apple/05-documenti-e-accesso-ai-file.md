# Documenti e accesso ai file

| Campo | Valore |
| --- | --- |
| Identificatore | GS-APL-005 |
| Tipo | Standard applicativo Apple |
| Versione | 0.1.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |

## Regole

- Importazione e apertura **DEVONO** passare attraverso picker o pannelli di sistema.
- Accesso persistente fuori dal container **DEVE** usare i meccanismi security-scoped previsti dalla piattaforma.
- Letture e scritture coordinate **DEVONO** rispettare modifiche esterne, provider di file e conflitti.
- Il salvataggio **DEVE** essere atomico o recuperabile e non lasciare un progetto dichiarato valido in stato parziale.
- File ricevuti da provider esterni **DEVONO** essere considerati input non affidabili e validati prima dell'uso.
- Path visualizzato e identità persistente **NON DEVONO** coincidere.
- Cache ricostruibili **DEVONO** risiedere in collocazioni appropriate e non essere incluse nei backup senza necessità.

La scelta tra `DocumentGroup`, package documentale e progetto gestito resta vincolata a DA-003 e DA-004. Riferimento: [Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox).
