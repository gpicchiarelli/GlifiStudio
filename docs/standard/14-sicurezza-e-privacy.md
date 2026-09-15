# 14. Sicurezza e privacy

| Campo | Valore |
| --- | --- |
| Identificatore | GS-STD-001-14 |
| Tipo | Capitolo normativo |
| Versione | 0.4.0 |
| Stato | Proposto |
| Responsabile | Da assegnare |
| Ultima modifica | 2026-09-15 |
| Approvazione | Non ancora approvato |
| Documento padre | [GS-STD-001](../standard-di-progetto.md) |

## 14.1 Pratiche di sviluppo sicuro

Il progetto applica le quattro aree del NIST SSDF: preparare l'organizzazione, proteggere il software, produrre software ben protetto e rispondere alle vulnerabilità.

## 14.2 Modellazione delle minacce

Prima di G2 devono essere modellate almeno le minacce relative a:

- parser di PDF, documenti strutturati e input malformati;
- path traversal, symlink e accesso a file non autorizzati;
- esaurimento di memoria, CPU o disco tramite input ostile;
- corruzione o sostituzione di progetto, indice e cache;
- fuga di contenuto tramite log, crash report o telemetria;
- dipendenze e strumenti di build compromessi;
- modelli ML o risorse esterne non affidabili.
- prompt injection, esfiltrazione tramite tool calling e confusione tra output generato e dati osservati.

## 14.3 Regole minime

- Il sistema **DEVE** applicare minimo privilegio a file, entitlement e processi.
- Dati testuali dell'utente **NON DEVONO** comparire nei log per impostazione predefinita.
- Credenziali e segreti **NON DEVONO** essere registrati nel repository o negli artefatti diagnostici.
- Telemetria contenente dati o metadati dell'utente **NON DEVE** essere attivata senza finalità, minimizzazione, informativa e consenso applicabili.
- File temporanei sensibili **DEVONO** avere permessi restrittivi e ciclo di vita definito.
- Limiti di parsing e allocazione **DEVONO** essere verificati prima dell'uso delle risorse.
- Vulnerabilità note **DEVONO** essere classificate, tracciate, corrette o derogate prima del rilascio.
- Contenuto dell'utente **NON DEVE** essere inviato a Private Cloud Compute o provider server senza requisito, minimizzazione, informativa e autorizzazione applicabili.
- Tool esposti a modelli generativi **DEVONO** applicare least authority, validazione degli argomenti e conferme per effetti irreversibili.

## 14.4 Risposta alle vulnerabilità

Ogni segnalazione **DEVE** ricevere identificatore, severità, responsabile, analisi dell'impatto e decisione. Una correzione di sicurezza **DEVE** includere un test di regressione quando riproducibile senza esporre materiale pericoloso.

Le app **DEVONO** applicare il profilo Apple dedicato a [privacy e sicurezza](../apple/04-privacy-e-sicurezza.md).

## 14.5 Repository e collaborazione

- Gli accessi al repository privato **DEVONO** seguire minimo privilegio, identità individuale, autenticazione forte e riesame periodico.
- Issue, pull request, log e artefatti CI **NON DEVONO** contenere documenti reali, dati personali o dettagli sfruttabili non necessari.
- Materiale di firma Apple **NON DEVE** essere disponibile a job di pull request.
- Un controllo locale euristico dei segreti **DEVE** essere affiancato da protezione server-side quando disponibile; nessuno dei due elimina la revisione.
- Una segnalazione di vulnerabilità **DEVE** usare il canale privato definito in [SECURITY.md](../../SECURITY.md).
- Un cambio di visibilità **DEVE** includere scansione dell'intera storia, verifica legale e rotazione preventiva delle credenziali interessate.
