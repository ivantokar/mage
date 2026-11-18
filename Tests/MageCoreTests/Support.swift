import Foundation
@testable import MageCore

func path(_ string: String) -> ProjectPath {
    try! ProjectPath(string)
}

let generatedHeader = OwnershipMarker.header()

func generated(_ body: String) -> String {
    "\(generatedHeader)\n\(body)\n"
}

/// Wraps a filesystem and fails exactly one mutating call (after N successful ones), to test rollback.
final class FailingFileSystem: FileSystem, @unchecked Sendable {
    struct Injected: Error {}
    let base: any FileSystem
    private let lock = NSLock()
    private var remaining: Int

    init(base: any FileSystem, failingAfter successfulMutations: Int) {
        self.base = base
        self.remaining = successfulMutations
    }

    private func mutate() throws {
        lock.lock(); defer { lock.unlock() }
        if remaining == 0 { remaining = -1; throw Injected() }
        if remaining > 0 { remaining -= 1 }
    }

    func kind(of path: ProjectPath) throws -> FileKind? { try base.kind(of: path) }
    func readFile(at path: ProjectPath) throws -> Data { try base.readFile(at: path) }
    func writeFile(_ data: Data, at path: ProjectPath) throws { try mutate(); try base.writeFile(data, at: path) }
    func createDirectory(at path: ProjectPath) throws { try mutate(); try base.createDirectory(at: path) }
    func removeFile(at path: ProjectPath) throws { try mutate(); try base.removeFile(at: path) }
    func removeDirectory(at path: ProjectPath) throws { try base.removeDirectory(at: path) }
    func contentsOfDirectory(at path: ProjectPath) throws -> [ProjectPath] { try base.contentsOfDirectory(at: path) }
}

/// A snapshot of every file and directory, for asserting "nothing changed".
func snapshot(_ fs: any FileSystem, at directory: ProjectPath = .root) throws -> [String] {
    var lines: [String] = []
    for child in try fs.contentsOfDirectory(at: directory) {
        switch try fs.kind(of: child) {
        case .directory:
            lines.append("d \(child)")
            lines += try snapshot(fs, at: child)
        case .file:
            lines.append("f \(child) = \(try fs.readString(at: child))")
        case nil:
            break
        }
    }
    return lines
}
