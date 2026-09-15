<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Istruzioni operative per agenti software

Queste istruzioni valgono per l'intero repository.

## Ordine delle fonti

1. richiesta esplicita dell'utente;
2. standard e requisiti controllati in `docs/`;
3. ADR accettati;
4. codice e test esistenti;
5. appunti grezzi, soltanto come provenienza non normativa.

Non modificare `appunti-1.txt` o `appunti 2.txt` salvo richiesta esplicita: sono record di origine incompleti.

## Vincoli di base

- Nome canonico: **Glifi Studio**; identificatori tecnici: `GlifiStudio` e `Glifi*`.
- Target iniziali: macOS 27 e iPadOS 27; Xcode 27 con Apple Swift 6.4 o
  successiva compatibile della serie 6; Swift 6 language mode e SwiftPM tools 6.4.
- Lingua iniziale: italiano; ogni elemento dell'interfaccia deve restare internazionalizzabile e accessibile.
- Usare `GlifiStudio.xcworkspace`, non aprire il solo progetto per il lavoro ordinario.
- Conservare la separazione fra app, `GlifiKit`, motore `GlifiCore` e strumenti headless.
- Preferire API Apple native dopo verifica di disponibilità e adottare accelerazioni soltanto su evidenza di profiling o benchmark.
- Non introdurre dipendenze, entitlement, rete, telemetria, sincronizzazione, formati persistenti o backend alternativi senza requisiti e decisioni applicabili.

## Metodo di modifica

- Preservare modifiche preesistenti e non ampliare lo scopo senza necessità.
- Aggiornare nello stesso cambiamento codice, test, documentazione, tracciabilità e ADR pertinenti.
- Non inserire segreti, firma Apple, dati personali, corpus reali o materiale di terzi non autorizzato.
- Non indebolire un controllo per far passare una modifica; correggere la causa o registrare una deroga formale.
- Aggiungere SPDX `BSD-3-Clause` ai nuovi file testuali che supportano commenti.
- Mantenere i documenti controllati in italiano, con un argomento per documento e identificatore univoco.

## Verifica

Eseguire il controllo più mirato durante il lavoro e `make verify` prima della consegna. Se un controllo non è eseguibile, dichiarare esattamente cosa manca e non presentare come verificato ciò che non lo è.
