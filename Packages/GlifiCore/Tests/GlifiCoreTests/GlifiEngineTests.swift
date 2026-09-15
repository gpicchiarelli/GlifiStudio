// SPDX-License-Identifier: BSD-3-Clause

import Testing

@testable import GlifiCore

@Test("Un nuovo motore segnala di essere pronto")
func newEngineIsReady() async {
    let engine = GlifiEngine()

    #expect(await engine.status() == .ready)
}

@Test("Un nuovo motore usa la configurazione linguistica italiana")
func newEngineUsesItalianLanguageConfiguration() async {
    let engine = GlifiEngine()

    #expect(await engine.languageConfiguration() == .italian)
    #expect(await engine.languageConfiguration().languageCode == "it")
    #expect(await engine.languageConfiguration().localeIdentifier == "it_IT")
}
