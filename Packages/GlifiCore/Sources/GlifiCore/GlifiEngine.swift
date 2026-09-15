// SPDX-License-Identifier: BSD-3-Clause

/// Describes the operational state of the GlifiCore engine.
public enum GlifiEngineStatus: String, Sendable, Equatable {
    /// The engine is available to accept work.
    case ready
}

/// Provides the headless entry point to GlifiCore capabilities.
public actor GlifiEngine {
    private let defaultLanguageConfiguration: GlifiLanguageConfiguration

    /// Creates an engine with no persistent project attached.
    ///
    /// - Parameter defaultLanguageConfiguration: The language used when a project has no explicit
    ///   language configuration.
    public init(defaultLanguageConfiguration: GlifiLanguageConfiguration = .italian) {
        self.defaultLanguageConfiguration = defaultLanguageConfiguration
    }

    /// Returns the language used when a project has no explicit configuration.
    public func languageConfiguration() -> GlifiLanguageConfiguration {
        defaultLanguageConfiguration
    }

    /// Returns the current operational state of the engine.
    public func status() -> GlifiEngineStatus {
        .ready
    }
}
