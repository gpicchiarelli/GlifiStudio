// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiKit
import SwiftUI
import UniformTypeIdentifiers

private enum StudioSection: String, CaseIterable, Identifiable {
    case overview
    case sources

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .overview:
            "sidebar.overview"
        case .sources:
            "sidebar.sources"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "square.grid.2x2"
        case .sources:
            "doc.text"
        }
    }
}

struct StudioHomeView: View {
    @State private var model = StudioHomeModel()
    @State private var selection: StudioSection? = .overview
    @State private var isImporterPresented = false

    var body: some View {
        NavigationSplitView {
            List(StudioSection.allCases, selection: $selection) { section in
                Label(section.titleKey, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("app.name")
        } detail: {
            switch selection ?? .overview {
            case .overview:
                overview
            case .sources:
                sources
            }
        }
        .toolbar {
            ToolbarItem {
                Button("action.import", systemImage: "plus") {
                    isImporterPresented = true
                }
                .disabled(isLoading)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else {
                return
            }
            selection = .sources
            Task {
                await model.profileFile(at: url)
            }
        }
        .task {
            await model.prepare()
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("home.question")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("home.description")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button("action.import", systemImage: "doc.badge.plus") {
                    isImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading)

                Text("import.allowed-formats")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                engineStatus
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("sidebar.overview")
    }

    @ViewBuilder
    private var sources: some View {
        switch model.profileState {
        case .empty:
            ContentUnavailableView {
                Label("sources.empty.title", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("sources.empty.description")
            } actions: {
                Button("action.import") {
                    isImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("sidebar.sources")
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                Text("import.progress")
                if let importedFileName = model.importedFileName {
                    Text(importedFileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("sidebar.sources")
        case let .ready(profile):
            profileView(profile)
        case let .failed(messageKey):
            ContentUnavailableView {
                Label("import.failure.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(LocalizedStringKey(messageKey))
            } actions: {
                Button("action.try-again") {
                    isImporterPresented = true
                }
            }
            .navigationTitle("sidebar.sources")
        }
    }

    private func profileView(_ profile: GlifiStudioTextProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("profile.title")
                        .font(.title.bold())
                    if let importedFileName = model.importedFileName {
                        Text(importedFileName)
                            .foregroundStyle(.secondary)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 16) {
                    GridRow {
                        metric("metric.characters", value: profile.characterCount)
                        metric("metric.sentences", value: profile.sentenceCount)
                    }
                    GridRow {
                        metric("metric.tokens", value: profile.lexicalTokenCount)
                        metric("metric.types", value: profile.typeCount)
                    }
                }

                Divider()

                Text("profile.top-terms")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ForEach(profile.topTerms.prefix(20)) { frequency in
                    LabeledContent(frequency.term) {
                        Text(frequency.count, format: .number)
                            .monospacedDigit()
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("sidebar.sources")
    }

    private func metric(_ title: LocalizedStringKey, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value, format: .number)
                .font(.title2.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var engineStatus: some View {
        Group {
            switch model.engineState {
            case .checking:
                Label("engine.status.checking", systemImage: "hourglass")
            case .ready:
                Label("engine.status.ready", systemImage: "checkmark.circle")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityLabel("engine.status.accessibility-label")
    }

    private var isLoading: Bool {
        if case .loading = model.profileState {
            return true
        }
        return false
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
