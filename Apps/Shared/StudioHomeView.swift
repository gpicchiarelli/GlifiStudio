// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiKit
import SwiftUI
import UniformTypeIdentifiers

private enum StudioSection: String, CaseIterable, Identifiable {
    case overview
    case project
    case sources
    case investigation
    case query
    case findings
    case export

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .overview: "sidebar.overview"
        case .project: "sidebar.project"
        case .sources: "sidebar.sources"
        case .investigation: "sidebar.investigation"
        case .query: "sidebar.query"
        case .findings: "sidebar.findings"
        case .export: "sidebar.export"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .project: "folder"
        case .sources: "doc.text"
        case .investigation: "lightbulb"
        case .query: "magnifyingglass"
        case .findings: "list.bullet.rectangle"
        case .export: "square.and.arrow.up"
        }
    }
}

struct StudioHomeView: View {
    var documentURL: URL?
    var needsPackageInitialization: Bool

    @State private var model = StudioHomeModel()
    @State private var selection: StudioSection? = .overview
    @State private var isSourceImporterPresented = false
    @State private var isProjectImporterPresented = false
    @State private var isExportFolderPresented = false

    init(documentURL: URL? = nil, needsPackageInitialization: Bool = false) {
        self.documentURL = documentURL
        self.needsPackageInitialization = needsPackageInitialization
    }

    var body: some View {
        NavigationSplitView {
            List(StudioSection.allCases, selection: $selection) { section in
                Label(section.titleKey, systemImage: section.systemImage)
                    .tag(section)
                    .accessibilityHint(section.titleKey)
            }
            .navigationTitle("app.name")
        } detail: {
            switch selection ?? .overview {
            case .overview: overview
            case .project: project
            case .sources: sources
            case .investigation: investigation
            case .query: query
            case .findings: findings
            case .export: export
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("action.new-project", systemImage: "folder.badge.plus") {
                    selection = .project
                    Task { await model.createProject() }
                }
                .disabled(model.isBusy)
                .accessibilityLabel("action.new-project")

                Button("action.open-project", systemImage: "folder") {
                    isProjectImporterPresented = true
                }
                .disabled(model.isBusy)
                .accessibilityLabel("action.open-project")

                Button("action.import", systemImage: "plus") {
                    isSourceImporterPresented = true
                }
                .disabled(model.isBusy || model.snapshot == nil)
                .accessibilityLabel("action.import")
            }
        }
        .fileImporter(
            isPresented: $isSourceImporterPresented,
            allowedContentTypes: [.plainText, .markdown],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result, !urls.isEmpty else {
                return
            }
            selection = .sources
            Task { await model.importSources(at: urls) }
        }
        .fileImporter(
            isPresented: $isProjectImporterPresented,
            allowedContentTypes: [.folder, .package],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else {
                return
            }
            guard url.pathExtension.lowercased() == "glifi" else {
                model.reportOpenFailure()
                return
            }
            selection = .project
            Task { await model.openProject(at: url) }
        }
        .fileImporter(
            isPresented: $isExportFolderPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else {
                return
            }
            Task { await model.exportInvestigation(to: url) }
        }
        .safeAreaInset(edge: .bottom) {
            statusBar
        }
        .task(id: documentURL?.path) {
            await model.prepare()
            await model.attachDocument(
                at: documentURL,
                needsPackageInitialization: needsPackageInitialization
            )
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
                Text("home.must-path")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("action.new-project", systemImage: "folder.badge.plus") {
                        selection = .project
                        Task { await model.createProject() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(model.isBusy)

                    Button("action.open-project", systemImage: "folder") {
                    isProjectImporterPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(model.isBusy)

                    Button("action.reopen-project", systemImage: "arrow.uturn.backward") {
                        selection = .project
                        Task { await model.reopenLastProject() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(model.isBusy || model.lastProjectBookmark == nil)
                }

                engineStatus
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("sidebar.overview")
    }

    private var project: some View {
        Form {
            Section("project.identity") {
                TextField("project.name", text: $model.projectNameDraft)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isBusy)
                    .accessibilityLabel("project.name")
                if let projectURL = model.projectURL {
                    LabeledContent("project.path") {
                        Text(projectURL.lastPathComponent)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
                if let snapshot = model.snapshot {
                    LabeledContent("project.generation") {
                        Text(snapshot.generation, format: .number)
                            .monospacedDigit()
                    }
                    LabeledContent("project.sources") {
                        Text(snapshot.sourceCount, format: .number)
                            .monospacedDigit()
                    }
                    LabeledContent("project.artifacts") {
                        Text(snapshot.artifactCount, format: .number)
                            .monospacedDigit()
                    }
                    LabeledContent("project.investigation-events") {
                        Text(snapshot.investigationEventCount, format: .number)
                            .monospacedDigit()
                    }
                } else {
                    ContentUnavailableView {
                        Label("project.empty.title", systemImage: "folder")
                    } description: {
                        Text("project.empty.description")
                    }
                }
            }
            Section {
                Button("action.new-project") {
                    Task { await model.createProject() }
                }
                .disabled(model.isBusy)
                Button("action.open-project") {
                    isProjectImporterPresented = true
                }
                .disabled(model.isBusy)
                Button("action.reopen-project") {
                    Task { await model.reopenLastProject() }
                }
                .disabled(model.isBusy || model.lastProjectBookmark == nil)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("sidebar.project")
    }

    @ViewBuilder
    private var sources: some View {
        if model.snapshot == nil {
            ContentUnavailableView {
                Label("sources.needs-project.title", systemImage: "folder.badge.questionmark")
            } description: {
                Text("sources.needs-project.description")
            } actions: {
                Button("action.new-project") {
                    selection = .project
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("sidebar.sources")
        } else {
            List {
                Section {
                    Button("action.import") {
                        isSourceImporterPresented = true
                    }
                    .disabled(model.isBusy)
                    Text("import.allowed-formats")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let lastProfile = model.lastProfile {
                    Section("profile.title") {
                        if let name = model.lastImportedFileName {
                            Text(name).foregroundStyle(.secondary)
                        }
                        metricRow("metric.characters", value: lastProfile.characterCount)
                        metricRow("metric.sentences", value: lastProfile.sentenceCount)
                        metricRow("metric.tokens", value: lastProfile.lexicalTokenCount)
                        metricRow("metric.types", value: lastProfile.typeCount)
                    }
                    Section("profile.top-terms") {
                        ForEach(lastProfile.topTerms.prefix(20)) { frequency in
                            LabeledContent(frequency.term) {
                                Text(frequency.count, format: .number)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                if let snapshot = model.snapshot, !snapshot.sources.isEmpty {
                    Section("sources.revisions") {
                        ForEach(snapshot.sources) { source in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.sourceRevisionID)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                                Text(source.format == .markdown ? "format.markdown" : "format.plain-text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .navigationTitle("sidebar.sources")
        }
    }

    private var investigation: some View {
        Form {
            Section("investigation.question") {
                TextField("investigation.question-prompt", text: $model.questionDraft, axis: .vertical)
                    .lineLimit(3...6)
                    .disabled(model.isBusy || model.snapshot == nil)
                    .accessibilityLabel("investigation.question-prompt")
                Picker("investigation.intent", selection: $model.selectedIntent) {
                    ForEach(StudioIntentOption.allCases) { intent in
                        Text(LocalizedStringKey(intent.titleKey)).tag(intent)
                    }
                }
                .disabled(model.isBusy || model.snapshot == nil)
                .accessibilityLabel("investigation.intent")
            }

            if let snapshot = model.snapshot, model.selectedIntent == .compareObjects {
                Section("investigation.compare-groups") {
                    ForEach(snapshot.sources) { source in
                        HStack {
                            Text(shortID(source.sourceRevisionID))
                                .font(.caption.monospaced())
                            Spacer()
                            Button("group.target") {
                                model.toggleTarget(source.sourceRevisionID)
                            }
                            .buttonStyle(.bordered)
                            .tint(model.selectedTargetRevisionIDs.contains(source.sourceRevisionID) ? .accentColor : .secondary)
                            Button("group.reference") {
                                model.toggleReference(source.sourceRevisionID)
                            }
                            .buttonStyle(.bordered)
                            .tint(model.selectedReferenceRevisionIDs.contains(source.sourceRevisionID) ? .accentColor : .secondary)
                        }
                    }
                }
            }

            Section {
                Button("action.plan") {
                    Task { await model.planInvestigation() }
                }
                .disabled(model.isBusy || model.snapshot == nil)
                Button("action.execute") {
                    Task { await model.executePlan() }
                }
                .disabled(model.isBusy || model.snapshot == nil)
                if model.canCancelExecution {
                    Button("action.cancel-execution", role: .cancel) {
                        model.cancelExecution()
                    }
                }
                Button("action.save-investigation") {
                    Task { await model.createInvestigationFromExecution() }
                }
                .disabled(model.isBusy || model.executionResult == nil)
            }

            if !model.investigationHeads.isEmpty {
                Section("investigation.heads") {
                    ForEach(model.investigationHeads, id: \.headEventID) { head in
                        Button {
                            model.selectInvestigationHead(head)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(head.question)
                                    .lineLimit(2)
                                Text(shortID(head.headEventID))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("investigation.heads")
                    }
                    Button("action.refresh-heads") {
                        Task { await model.refreshInvestigationHeads() }
                    }
                    .disabled(model.isBusy)
                }
            }

            if let plan = model.planResult {
                Section("plan.title") {
                    LabeledContent("plan.status") {
                        Text(plan.plan.status)
                    }
                    LabeledContent("plan.sources") {
                        Text(plan.plan.collectionProfile.sourceCount, format: .number)
                            .monospacedDigit()
                    }
                    ForEach(Array(plan.plan.steps.enumerated()), id: \.element.identifier) { _, step in
                        LabeledContent(step.capabilityIdentifier) {
                            Text(step.operation)
                                .font(.caption.monospaced())
                        }
                    }
                    ForEach(Array(plan.plan.decisions.enumerated()), id: \.offset) { _, decision in
                        LabeledContent(decision.capabilityIdentifier) {
                            Text(decision.applicability)
                                .font(.caption)
                        }
                    }
                }
            }

            if let progress = model.executionProgress {
                Section("execution.progress") {
                    ProgressView(
                        value: Double(progress.completed),
                        total: Double(progress.total ?? max(progress.completed, 1))
                    )
                    Text(progress.phase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("execution.progress")
                }
            }

            if let investigation = model.investigation {
                Section("investigation.saved") {
                    LabeledContent("investigation.id") {
                        Text(shortID(investigation.id))
                            .font(.caption.monospaced())
                    }
                    LabeledContent("investigation.head") {
                        Text(shortID(investigation.headEventID))
                            .font(.caption.monospaced())
                    }
                    Text(investigation.question)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("sidebar.investigation")
        .disabled(model.snapshot == nil && !model.isBusy)
    }

    private var query: some View {
        Form {
            Section("query.editor") {
                TextField("query.placeholder", text: $model.queryDraft)
                    .disabled(model.isBusy || model.snapshot == nil)
                    .accessibilityLabel("query.placeholder")
                Button("action.search") {
                    Task { await model.runQuery() }
                }
                .disabled(model.isBusy || model.snapshot == nil)
            }
            if let queryResult = model.queryResult {
                Section("query.results") {
                    LabeledContent("query.matches") {
                        Text(queryResult.matches.count, format: .number)
                            .monospacedDigit()
                    }
                    if queryResult.isTruncated {
                        Text("query.truncated")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(queryResult.matches) { match in
                        Button {
                            Task { await model.selectQueryMatch(match) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(shortID(match.sourceRevisionID))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                (
                                    Text(match.leftContext).foregroundStyle(.secondary)
                                        + Text(match.match).bold()
                                        + Text(match.rightContext).foregroundStyle(.secondary)
                                )
                                .textSelection(.enabled)
                                Text("\(match.startUTF8)–\(match.endUTF8)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("query.match.accessibility")
                        .accessibilityAddTraits(
                            model.selectedQueryMatchID == match.id
                                ? AccessibilityTraits.isSelected
                                : AccessibilityTraits()
                        )
                    }
                }
            }
            if let sourceText = model.sourceText, let match = model.selectedQueryMatch {
                Section("query.source") {
                    Text(shortID(sourceText.sourceRevisionID))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    highlightedSource(sourceText.text, ranges: match.sourceRanges)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .accessibilityLabel("query.source")
                    ForEach(Array(match.sourceRanges.enumerated()), id: \.offset) { _, range in
                        LabeledContent("source.bytes") {
                            Text("\(range.start)–\(range.end)")
                                .font(.caption2.monospaced())
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("sidebar.query")
    }

    private var findings: some View {
        Group {
            if let insufficient = model.insufficientEvidence, model.findings.isEmpty {
                ContentUnavailableView {
                    Label("findings.insufficient.title", systemImage: "exclamationmark.bubble")
                } description: {
                    Text(LocalizedStringKey(insufficient.messageKey))
                }
            } else if model.findings.isEmpty {
                ContentUnavailableView {
                    Label("findings.empty.title", systemImage: "list.bullet.rectangle")
                } description: {
                    Text("findings.empty.description")
                }
            } else {
                HStack(spacing: 0) {
                    List(model.findings, id: \.id, selection: Binding(
                        get: { model.selectedFindingID },
                        set: { if let value = $0 { model.selectFinding(id: value) } }
                    )) { finding in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(finding.messageKey))
                            Text(finding.supportClassLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(finding.id)
                        .accessibilityElement(children: .combine)
                    }
                    .frame(minWidth: 220, idealWidth: 280)

                    Divider()

                    if let finding = model.selectedFinding {
                        findingDetail(finding)
                    } else {
                        ContentUnavailableView {
                            Label("findings.empty.title", systemImage: "list.bullet.rectangle")
                        } description: {
                            Text("findings.empty.description")
                        }
                    }
                }
            }
        }
        .navigationTitle("sidebar.findings")
    }

    private func findingDetail(_ finding: GlifiStudioFinding) -> some View {
        Form {
            Section("finding.proposition") {
                Text(LocalizedStringKey(finding.messageKey))
                LabeledContent("finding.family") {
                    Text(finding.familyIdentifier)
                        .font(.caption.monospaced())
                }
                LabeledContent("finding.state") {
                    Text(finding.state)
                }
            }
            Section("finding.caveats") {
                if finding.caveats.isEmpty {
                    Text("finding.caveats.none")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(finding.caveats.enumerated()), id: \.offset) { _, caveat in
                        Text(LocalizedStringKey(caveat.identifier))
                    }
                }
            }
            Section("finding.evidence") {
                if model.evidenceForSelectedFinding.isEmpty {
                    Text("finding.evidence.none")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.evidenceForSelectedFinding, id: \.id) { evidence in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(evidence.kindIdentifier)
                                .font(.caption.monospaced())
                            Text(shortID(evidence.id))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            Section("finding.lineage") {
                LabeledContent("finding.has-lineage") {
                    Text(finding.rankFactors.hasCompleteLineage ? "common.yes" : "common.no")
                }
            }
            Section("finding.editorial") {
                Toggle(
                    "finding.editorial.include",
                    isOn: Binding(
                        get: { model.editorialSelectedFindingIDs.contains(finding.id) },
                        set: { _ in model.toggleEditorialSelection(id: finding.id) }
                    )
                )
                .accessibilityLabel("finding.editorial.include")
                Button("action.revise-selection") {
                    Task { await model.reviseEditorialSelection() }
                }
                .disabled(model.isBusy || model.investigation == nil)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("finding.detail")
    }

    private var export: some View {
        Form {
            Section("export.description") {
                Text("export.help")
                    .foregroundStyle(.secondary)
                Button("action.export") {
                    isExportFolderPresented = true
                }
                .disabled(model.isBusy || model.investigation == nil)
                .accessibilityLabel("action.export")
            }
            if let receipt = model.exportReceipt {
                Section("export.receipt") {
                    LabeledContent("export.id") {
                        Text(shortID(receipt.exportID))
                            .font(.caption.monospaced())
                    }
                    LabeledContent("export.files") {
                        Text(receipt.fileCount, format: .number)
                            .monospacedDigit()
                    }
                    LabeledContent("export.manifest") {
                        Text(shortID(receipt.manifestDigest))
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("sidebar.export")
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            engineStatus
            if case let .working(messageKey) = model.busyState {
                ProgressView()
                    .controlSize(.small)
                Text(LocalizedStringKey(messageKey))
                    .font(.caption)
            }
            if let failureMessageKey = model.failureMessageKey {
                Label(LocalizedStringKey(failureMessageKey), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel(LocalizedStringKey(failureMessageKey))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
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

    private func metricRow(_ title: LocalizedStringKey, value: Int) -> some View {
        LabeledContent(title) {
            Text(value, format: .number)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func highlightedSource(_ text: String, ranges: [GlifiStudioUTF8Range]) -> some View {
        let attributed = attributedSource(text, ranges: ranges)
        Text(attributed)
    }

    private func attributedSource(_ text: String, ranges: [GlifiStudioUTF8Range]) -> AttributedString {
        var attributed = AttributedString(text)
        let utf8 = text.utf8
        for range in ranges {
            guard
                let utf8Start = utf8.index(
                    utf8.startIndex,
                    offsetBy: range.start,
                    limitedBy: utf8.endIndex
                ),
                let utf8End = utf8.index(
                    utf8.startIndex,
                    offsetBy: range.end,
                    limitedBy: utf8.endIndex
                ),
                let start = String.Index(utf8Start, within: text),
                let end = String.Index(utf8End, within: text),
                let lower = AttributedString.Index(start, within: attributed),
                let upper = AttributedString.Index(end, within: attributed)
            else {
                continue
            }
            attributed[lower..<upper].backgroundColor = .yellow.opacity(0.35)
            attributed[lower..<upper].font = .body.monospaced().bold()
        }
        return attributed
    }

    private func shortID(_ value: String) -> String {
        if value.count <= 24 {
            return value
        }
        return String(value.prefix(12)) + "…" + String(value.suffix(8))
    }
}

private extension GlifiStudioFinding {
    var supportClassLabel: String {
        assessment.supportClass
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

#Preview("Document") {
    StudioHomeView(
        documentURL: URL(filePath: "/tmp/Anteprima.glifi"),
        needsPackageInitialization: true
    )
}
