// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import SwiftUI

struct StudioHomeView: View {
    @State private var model = StudioHomeModel()

    private var engineStatusText: Text {
        switch model.engineState {
        case .checking:
            Text("engine.status.checking")
        case .ready:
            Text("engine.status.ready")
        }
    }

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("app.name", systemImage: "text.book.closed")
            } description: {
                Text("home.description")
            } actions: {
                engineStatusText
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("engine.status.accessibility-label")
                    .accessibilityValue(engineStatusText)
            }
            .navigationTitle("app.name")
        }
        .task {
            await model.prepare()
        }
    }
}

#Preview("Italiano") {
    StudioHomeView()
        .environment(\.locale, Locale(identifier: "it"))
}

#Preview("English · Dynamic Type") {
    StudioHomeView()
        .environment(\.locale, Locale(identifier: "en"))
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Right to left") {
    StudioHomeView()
        .environment(\.layoutDirection, .rightToLeft)
}
