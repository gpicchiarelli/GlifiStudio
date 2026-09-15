// SPDX-License-Identifier: BSD-3-Clause

import Darwin
import Foundation
import SQLite3

final class GlifiSQLiteProjectStore {
    struct Generation {
        let baseGeneration: Int?
        let state: String
        let recordDigest: String
        let sourceRootDigest: String
        let sourceCount: Int
        let artifactRootDigest: String
        let artifactCount: Int
    }

    private var database: OpaquePointer?

    private init(database: OpaquePointer) {
        self.database = database
    }

    deinit {
        sqlite3_close(database)
    }

    static func create(at url: URL, projectID: ProjectID) throws -> GlifiSQLiteProjectStore {
        let store = try openDatabase(at: url, flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE)
        try store.configure()
        try store.execute(
            """
            CREATE TABLE project_metadata (
                singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
                project_id TEXT NOT NULL,
                schema_version INTEGER NOT NULL CHECK (schema_version = 2)
            ) STRICT;
            CREATE TABLE generations (
                generation INTEGER PRIMARY KEY CHECK (generation >= 0),
                base_generation INTEGER,
                state TEXT NOT NULL CHECK (state IN ('prepared', 'committed')),
                record_digest TEXT NOT NULL,
                source_root_digest TEXT NOT NULL,
                source_count INTEGER NOT NULL CHECK (source_count >= 0),
                artifact_root_digest TEXT NOT NULL,
                artifact_count INTEGER NOT NULL CHECK (artifact_count >= 0)
            ) STRICT;
            CREATE TABLE source_entries (
                generation INTEGER NOT NULL,
                source_id TEXT NOT NULL,
                source_revision_id TEXT NOT NULL,
                format TEXT NOT NULL CHECK (format IN ('plainText', 'markdown')),
                content_digest TEXT NOT NULL,
                byte_count INTEGER NOT NULL CHECK (byte_count >= 0),
                object_path TEXT NOT NULL,
                PRIMARY KEY (generation, source_revision_id),
                FOREIGN KEY (generation) REFERENCES generations(generation) ON DELETE CASCADE
            ) STRICT;
            CREATE TABLE artifact_entries (
                generation INTEGER NOT NULL,
                node_id TEXT NOT NULL,
                artifact_id TEXT NOT NULL,
                descriptor_digest TEXT NOT NULL,
                descriptor_byte_count INTEGER NOT NULL CHECK (descriptor_byte_count >= 0),
                descriptor_object_path TEXT NOT NULL,
                content_digest TEXT NOT NULL,
                byte_count INTEGER NOT NULL CHECK (byte_count >= 0),
                object_path TEXT NOT NULL,
                output_schema_identifier TEXT NOT NULL,
                PRIMARY KEY (generation, node_id),
                FOREIGN KEY (generation) REFERENCES generations(generation) ON DELETE CASCADE
            ) STRICT;
            """
        )
        try store.withStatement(
            "INSERT INTO project_metadata(singleton, project_id, schema_version) VALUES(1, ?, 2)"
        ) { statement in
            try store.bind(projectID.canonicalValue, at: 1, to: statement)
            try store.expectDone(statement)
        }
        return store
    }

    static func open(at url: URL) throws -> GlifiSQLiteProjectStore {
        var status = stat()
        guard lstat(url.path, &status) == 0,
            (status.st_mode & S_IFMT) == S_IFREG,
            status.st_nlink == 1
        else {
            throw failure("project.invalid-store-file", category: .corruption)
        }
        let store = try openDatabase(at: url, flags: SQLITE_OPEN_READWRITE)
        try store.configure()
        return store
    }

    func insertInitialGeneration(
        recordDigest: String,
        sourceRootDigest: String,
        artifactRootDigest: String
    ) throws {
        try withStatement(
            """
            INSERT INTO generations(
                generation, base_generation, state, record_digest, source_root_digest, source_count,
                artifact_root_digest, artifact_count
            ) VALUES(0, NULL, 'committed', ?, ?, 0, ?, 0)
            """
        ) { statement in
            try bind(recordDigest, at: 1, to: statement)
            try bind(sourceRootDigest, at: 2, to: statement)
            try bind(artifactRootDigest, at: 3, to: statement)
            try expectDone(statement)
        }
    }

    func validateIntegrity(projectID: ProjectID) throws {
        let quickCheck = try scalarText("PRAGMA quick_check(1)")
        guard quickCheck == "ok" else {
            throw Self.failure("project.store-integrity-failed", category: .corruption)
        }
        let foreignKeys = try scalarInt("PRAGMA foreign_key_check", allowNoRows: true)
        guard foreignKeys == nil else {
            throw Self.failure("project.store-foreign-key-failed", category: .corruption)
        }
        let storedProjectID = try scalarText(
            "SELECT project_id FROM project_metadata WHERE singleton = 1 AND schema_version = 2"
        )
        guard storedProjectID == projectID.canonicalValue else {
            throw Self.failure("project.store-project-mismatch", category: .corruption)
        }
    }

    func generation(_ generation: Int) throws -> Generation {
        try withStatement(
            """
            SELECT base_generation, state, record_digest, source_root_digest, source_count,
                   artifact_root_digest, artifact_count
            FROM generations WHERE generation = ?
            """
        ) { statement in
            try bind(generation, at: 1, to: statement)
            guard sqlite3_step(statement) == SQLITE_ROW,
                let state = text(at: 1, in: statement),
                let recordDigest = text(at: 2, in: statement),
                let sourceRootDigest = text(at: 3, in: statement),
                let artifactRootDigest = text(at: 5, in: statement)
            else {
                throw Self.failure("project.generation-missing", category: .corruption)
            }
            let baseGeneration =
                sqlite3_column_type(statement, 0) == SQLITE_NULL
                ? nil : Int(sqlite3_column_int64(statement, 0))
            return Generation(
                baseGeneration: baseGeneration,
                state: state,
                recordDigest: recordDigest,
                sourceRootDigest: sourceRootDigest,
                sourceCount: Int(sqlite3_column_int64(statement, 4)),
                artifactRootDigest: artifactRootDigest,
                artifactCount: Int(sqlite3_column_int64(statement, 6))
            )
        }
    }

    func sources(generation: Int) throws -> [GlifiProjectSourceRecord] {
        try withStatement(
            """
            SELECT source_id, source_revision_id, format, content_digest, byte_count, object_path
            FROM source_entries
            WHERE generation = ?
            ORDER BY source_revision_id COLLATE BINARY ASC
            """
        ) { statement in
            try bind(generation, at: 1, to: statement)
            var result: [GlifiProjectSourceRecord] = []
            while true {
                let status = sqlite3_step(statement)
                if status == SQLITE_DONE { break }
                guard status == SQLITE_ROW,
                    let sourceIDText = text(at: 0, in: statement),
                    let sourceRevisionIDText = text(at: 1, in: statement),
                    let formatText = text(at: 2, in: statement),
                    let contentDigest = text(at: 3, in: statement),
                    let objectPath = text(at: 5, in: statement),
                    let format = GlifiTextFormat(rawValue: formatText)
                else {
                    throw Self.failure("project.invalid-source-row", category: .corruption)
                }
                result.append(
                    GlifiProjectSourceRecord(
                        sourceID: try SourceID(canonicalValue: sourceIDText),
                        sourceRevisionID: try SourceRevisionID(
                            canonicalValue: sourceRevisionIDText
                        ),
                        format: format,
                        contentDigest: contentDigest,
                        byteCount: Int(sqlite3_column_int64(statement, 4)),
                        objectPath: objectPath
                    )
                )
            }
            return result
        }
    }

    func artifacts(generation: Int) throws -> [GlifiStoredProjectArtifactRecord] {
        try withStatement(
            """
            SELECT artifact_id, node_id, descriptor_digest, descriptor_byte_count,
                   descriptor_object_path, content_digest, byte_count, object_path,
                   output_schema_identifier
            FROM artifact_entries
            WHERE generation = ?
            ORDER BY node_id COLLATE BINARY ASC
            """
        ) { statement in
            try bind(generation, at: 1, to: statement)
            var result: [GlifiStoredProjectArtifactRecord] = []
            while true {
                let status = sqlite3_step(statement)
                if status == SQLITE_DONE { break }
                guard status == SQLITE_ROW,
                    let artifactIDText = text(at: 0, in: statement),
                    let nodeIDText = text(at: 1, in: statement),
                    let descriptorDigest = text(at: 2, in: statement),
                    let descriptorObjectPath = text(at: 4, in: statement),
                    let contentDigest = text(at: 5, in: statement),
                    let objectPath = text(at: 7, in: statement),
                    let outputSchemaIdentifier = text(at: 8, in: statement)
                else {
                    throw Self.failure("project.invalid-artifact-row", category: .corruption)
                }
                do {
                    result.append(
                        GlifiStoredProjectArtifactRecord(
                            artifactID: try ArtifactID(canonicalValue: artifactIDText),
                            nodeID: try AnalysisNodeID(canonicalValue: nodeIDText),
                            descriptorDigest: descriptorDigest,
                            descriptorByteCount: Int(sqlite3_column_int64(statement, 3)),
                            descriptorObjectPath: descriptorObjectPath,
                            contentDigest: contentDigest,
                            byteCount: Int(sqlite3_column_int64(statement, 6)),
                            objectPath: objectPath,
                            outputSchemaIdentifier: outputSchemaIdentifier
                        )
                    )
                } catch {
                    throw Self.failure("project.invalid-artifact-row", category: .corruption)
                }
            }
            return result
        }
    }

    func prepareSourceGeneration(
        generation: Int,
        baseGeneration: Int,
        recordDigest: String,
        sourceRootDigest: String,
        artifactRootDigest: String,
        source: GlifiProjectSourceRecord
    ) throws {
        try transaction {
            try withStatement(
                """
                INSERT INTO generations(
                    generation, base_generation, state, record_digest, source_root_digest, source_count,
                    artifact_root_digest, artifact_count
                )
                SELECT ?, ?, 'prepared', ?, ?, source_count + 1, ?, 0
                FROM generations
                WHERE generation = ? AND state IN ('prepared', 'committed')
                """
            ) { statement in
                try bind(generation, at: 1, to: statement)
                try bind(baseGeneration, at: 2, to: statement)
                try bind(recordDigest, at: 3, to: statement)
                try bind(sourceRootDigest, at: 4, to: statement)
                try bind(artifactRootDigest, at: 5, to: statement)
                try bind(baseGeneration, at: 6, to: statement)
                try expectDone(statement)
                guard sqlite3_changes(database) == 1 else {
                    throw Self.failure("project.stale-generation", category: .staleArtifact)
                }
            }
            try withStatement(
                """
                INSERT INTO source_entries(
                    generation, source_id, source_revision_id, format,
                    content_digest, byte_count, object_path
                )
                SELECT ?, source_id, source_revision_id, format,
                       content_digest, byte_count, object_path
                FROM source_entries WHERE generation = ?
                """
            ) { statement in
                try bind(generation, at: 1, to: statement)
                try bind(baseGeneration, at: 2, to: statement)
                try expectDone(statement)
            }
            try withStatement(
                """
                INSERT INTO source_entries(
                    generation, source_id, source_revision_id, format,
                    content_digest, byte_count, object_path
                ) VALUES(?, ?, ?, ?, ?, ?, ?)
                """
            ) { statement in
                try bind(generation, at: 1, to: statement)
                try bind(source.sourceID.canonicalValue, at: 2, to: statement)
                try bind(source.sourceRevisionID.canonicalValue, at: 3, to: statement)
                try bind(source.format.rawValue, at: 4, to: statement)
                try bind(source.contentDigest, at: 5, to: statement)
                try bind(source.byteCount, at: 6, to: statement)
                try bind(source.objectPath, at: 7, to: statement)
                try expectDone(statement)
            }
        }
    }

    func prepareArtifactGeneration(
        generation: Int,
        baseGeneration: Int,
        recordDigest: String,
        sourceRootDigest: String,
        artifactRootDigest: String,
        artifacts: [GlifiStoredProjectArtifactRecord]
    ) throws {
        try transaction {
            try withStatement(
                """
                INSERT INTO generations(
                    generation, base_generation, state, record_digest, source_root_digest, source_count,
                    artifact_root_digest, artifact_count
                )
                SELECT ?, ?, 'prepared', ?, ?, source_count, ?, ?
                FROM generations
                WHERE generation = ? AND state IN ('prepared', 'committed')
                """
            ) { statement in
                try bind(generation, at: 1, to: statement)
                try bind(baseGeneration, at: 2, to: statement)
                try bind(recordDigest, at: 3, to: statement)
                try bind(sourceRootDigest, at: 4, to: statement)
                try bind(artifactRootDigest, at: 5, to: statement)
                try bind(artifacts.count, at: 6, to: statement)
                try bind(baseGeneration, at: 7, to: statement)
                try expectDone(statement)
                guard sqlite3_changes(database) == 1 else {
                    throw Self.failure("project.stale-generation", category: .staleArtifact)
                }
            }
            try withStatement(
                """
                INSERT INTO source_entries(
                    generation, source_id, source_revision_id, format,
                    content_digest, byte_count, object_path
                )
                SELECT ?, source_id, source_revision_id, format,
                       content_digest, byte_count, object_path
                FROM source_entries WHERE generation = ?
                """
            ) { statement in
                try bind(generation, at: 1, to: statement)
                try bind(baseGeneration, at: 2, to: statement)
                try expectDone(statement)
            }
            try withStatement(
                """
                INSERT INTO artifact_entries(
                    generation, node_id, artifact_id, descriptor_digest,
                    descriptor_byte_count, descriptor_object_path, content_digest,
                    byte_count, object_path, output_schema_identifier
                ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
            ) { statement in
                for artifact in artifacts {
                    sqlite3_reset(statement)
                    sqlite3_clear_bindings(statement)
                    try bind(generation, at: 1, to: statement)
                    try bind(artifact.nodeID.canonicalValue, at: 2, to: statement)
                    try bind(artifact.artifactID.canonicalValue, at: 3, to: statement)
                    try bind(artifact.descriptorDigest, at: 4, to: statement)
                    try bind(artifact.descriptorByteCount, at: 5, to: statement)
                    try bind(artifact.descriptorObjectPath, at: 6, to: statement)
                    try bind(artifact.contentDigest, at: 7, to: statement)
                    try bind(artifact.byteCount, at: 8, to: statement)
                    try bind(artifact.objectPath, at: 9, to: statement)
                    try bind(artifact.outputSchemaIdentifier, at: 10, to: statement)
                    try expectDone(statement)
                }
            }
        }
    }

    func discardGenerations(after generation: Int) throws {
        try withStatement("DELETE FROM generations WHERE generation > ?") { statement in
            try bind(generation, at: 1, to: statement)
            try expectDone(statement)
        }
    }

    func markCommitted(generation: Int) throws {
        try withStatement(
            "UPDATE generations SET state = 'committed' WHERE generation = ? AND state = 'prepared'"
        ) { statement in
            try bind(generation, at: 1, to: statement)
            try expectDone(statement)
        }
    }

    private static func openDatabase(at url: URL, flags: Int32) throws -> GlifiSQLiteProjectStore {
        var pointer: OpaquePointer?
        let result = sqlite3_open_v2(
            url.path,
            &pointer,
            flags | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard result == SQLITE_OK, let pointer else {
            if let pointer { sqlite3_close(pointer) }
            throw failure("project.store-open-failed", category: .transientIO)
        }
        return GlifiSQLiteProjectStore(database: pointer)
    }

    private func configure() throws {
        guard sqlite3_busy_timeout(database, 5_000) == SQLITE_OK else {
            throw Self.failure("project.store-timeout-configuration-failed")
        }
        try execute(
            "PRAGMA foreign_keys = ON; PRAGMA journal_mode = DELETE; PRAGMA synchronous = FULL;")
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        sqlite3_free(errorMessage)
        guard result == SQLITE_OK else {
            throw Self.failure("project.store-statement-failed")
        }
    }

    private func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try body()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func withStatement<T>(_ sql: String, body: (OpaquePointer) throws -> T) throws -> T {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
            let statement
        else {
            throw Self.failure("project.store-prepare-failed")
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func scalarText(_ sql: String) throws -> String {
        try withStatement(sql) { statement in
            guard sqlite3_step(statement) == SQLITE_ROW, let value = text(at: 0, in: statement)
            else {
                throw Self.failure("project.store-scalar-missing", category: .corruption)
            }
            return value
        }
    }

    private func scalarInt(_ sql: String, allowNoRows: Bool) throws -> Int? {
        try withStatement(sql) { statement in
            let result = sqlite3_step(statement)
            if allowNoRows, result == SQLITE_DONE { return nil }
            guard result == SQLITE_ROW else {
                throw Self.failure("project.store-scalar-invalid", category: .corruption)
            }
            return Int(sqlite3_column_int64(statement, 0))
        }
    }

    private func bind(_ value: String, at index: Int32, to statement: OpaquePointer) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        guard sqlite3_bind_text(statement, index, value, -1, transient) == SQLITE_OK else {
            throw Self.failure("project.store-bind-failed")
        }
    }

    private func bind(_ value: Int, at index: Int32, to statement: OpaquePointer) throws {
        guard sqlite3_bind_int64(statement, index, sqlite3_int64(value)) == SQLITE_OK else {
            throw Self.failure("project.store-bind-failed")
        }
    }

    private func expectDone(_ statement: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw Self.failure("project.store-statement-failed")
        }
    }

    private func text(at index: Int32, in statement: OpaquePointer) -> String? {
        guard let bytes = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: bytes)
    }

    private static func failure(
        _ code: String,
        category: GlifiFailureCategory = .transientIO
    ) -> GlifiFailure {
        GlifiFailure(
            code: code,
            category: category,
            operation: .persistProject,
            retryDisposition: category == .staleArtifact ? .newRequest : .transientBackoff,
            retainedState: category == .corruption ? .readOnlyRecovery : .lastCommittedGeneration,
            messageKey: category == .corruption
                ? "failure.project.corruption" : "failure.project.io-failed"
        )
    }
}
