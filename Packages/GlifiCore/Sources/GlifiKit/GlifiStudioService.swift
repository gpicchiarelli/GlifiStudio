// SPDX-License-Identifier: BSD-3-Clause

import GlifiCore

/// Represents a stable, presentation-independent status exposed by GlifiKit.
public enum GlifiStudioStatus: String, Sendable, Equatable {
    /// The engine is ready to accept work.
    case ready
}

/// Exposes the public application-facing contract for GlifiCore.
public struct GlifiStudioService: Sendable {
    private let engine: GlifiEngine

    /// Creates a service backed by a new GlifiCore engine.
    public init() {
        engine = GlifiEngine()
    }

    /// Returns a presentation-independent description of the engine state.
    public func status() async -> GlifiStudioStatus {
        let engineStatus = await engine.status()

        switch engineStatus {
        case .ready:
            return .ready
        }
    }
}
