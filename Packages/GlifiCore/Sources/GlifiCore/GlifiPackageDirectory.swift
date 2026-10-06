// SPDX-License-Identifier: BSD-3-Clause

import Darwin
import Foundation

final class GlifiPackageDirectory {
    private let descriptor: Int32

    init(at url: URL) throws {
        guard url.isFileURL, !url.path.contains("\0") else {
            throw Self.corruption()
        }
        let descriptor = Darwin.open(
            url.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
        guard descriptor >= 0 else { throw Self.corruption() }
        self.descriptor = descriptor
    }

    private init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        Darwin.close(descriptor)
    }

    func openDirectory(named name: String) throws -> GlifiPackageDirectory {
        guard try Self.components(of: name).count == 1 else { throw Self.corruption() }
        let child = withExtendedLifetime(self) {
            openat(descriptor, name, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        }
        guard child >= 0 else { throw Self.corruption() }
        return GlifiPackageDirectory(descriptor: child)
    }

    func openFile(relativePath: String) throws -> FileHandle {
        let components = try Self.components(of: relativePath)
        guard let name = components.last else { throw Self.corruption() }
        var directory = self
        for component in components.dropLast() {
            directory = try directory.openDirectory(named: component)
        }
        let file = withExtendedLifetime(directory) {
            openat(
                directory.descriptor, name, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK
            )
        }
        guard file >= 0 else { throw Self.corruption() }
        return FileHandle(fileDescriptor: file, closeOnDealloc: true)
    }

    func createDirectory(relativePath: String) throws -> GlifiPackageDirectory {
        let components = try Self.components(of: relativePath)
        var directory = self
        for component in components {
            let (result, error) = withExtendedLifetime(directory) {
                (mkdirat(directory.descriptor, component, 0o700), errno)
            }
            guard result == 0 || error == EEXIST else {
                throw Self.writeFailure()
            }
            directory = try directory.openDirectory(named: component)
        }
        return directory
    }

    func moveFile(
        named name: String,
        to directory: GlifiPackageDirectory,
        named destinationName: String
    ) throws -> Bool {
        guard try Self.components(of: name).count == 1,
            try Self.components(of: destinationName).count == 1
        else {
            throw Self.corruption()
        }
        let (result, error) = withExtendedLifetime((self, directory)) {
            (
                renameatx_np(
                    descriptor, name, directory.descriptor, destinationName, UInt32(RENAME_EXCL)),
                errno
            )
        }
        if result == 0 { return true }
        if error == EEXIST { return false }
        throw Self.writeFailure()
    }

    private static func components(of path: String) throws -> [String] {
        guard !path.isEmpty, path.utf8.count <= 256,
            !path.contains("\0"), !path.contains("\\")
        else {
            throw corruption()
        }
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw corruption()
        }
        return components.map(String.init)
    }

    private static func corruption() -> GlifiFailure {
        GlifiFailure(
            code: "project.invalid-object-path",
            category: .corruption,
            operation: .persistProject,
            retryDisposition: .never,
            retainedState: .readOnlyRecovery,
            messageKey: "failure.project.corruption"
        )
    }

    private static func writeFailure() -> GlifiFailure {
        GlifiFailure(
            code: "project.object-promotion-io-failed",
            category: .transientIO,
            operation: .persistProject,
            retryDisposition: .transientBackoff,
            retainedState: .lastCommittedGeneration,
            messageKey: "failure.project.file-create-failed"
        )
    }
}
