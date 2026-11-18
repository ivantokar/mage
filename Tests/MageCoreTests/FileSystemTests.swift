import Foundation
import Testing
@testable import MageCore

/// Both implementations must satisfy the same contract.
@Suite struct FileSystemContractTests {
    static func makeFileSystems() -> [(String, any FileSystem, cleanup: @Sendable () -> Void)] {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("mage-fs-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return [
            ("in-memory", InMemoryFileSystem(), {}),
            ("local", LocalFileSystem(root: directory), { try? FileManager.default.removeItem(at: directory) }),
        ]
    }

    @Test func fileLifecycle() throws {
        for (name, fs, cleanup) in Self.makeFileSystems() {
            defer { cleanup() }
            let dir = try ProjectPath("Sources")
            let file = try ProjectPath("Sources/a.txt")

            #expect(try fs.kind(of: dir) == nil, "\(name)")
            try fs.createDirectory(at: dir)
            #expect(try fs.kind(of: dir) == .directory, "\(name)")
            try fs.writeString("hello", at: file)
            #expect(try fs.readString(at: file) == "hello", "\(name)")
            #expect(try fs.kind(of: file) == .file, "\(name)")
            #expect(try fs.contentsOfDirectory(at: dir) == [file], "\(name)")
            #expect(try fs.contentsOfDirectory(at: .root) == [dir], "\(name)")

            try fs.writeString("again", at: file)
            #expect(try fs.readString(at: file) == "again", "\(name)")

            #expect(throws: FileSystemError.directoryNotEmpty(dir), "\(name)") { try fs.removeDirectory(at: dir) }
            try fs.removeFile(at: file)
            try fs.removeDirectory(at: dir)
            #expect(try fs.kind(of: dir) == nil, "\(name)")
        }
    }

    @Test func errors() throws {
        for (name, fs, cleanup) in Self.makeFileSystems() {
            defer { cleanup() }
            let missing = try ProjectPath("missing/a.txt")
            #expect(throws: FileSystemError.notFound(try ProjectPath("missing")), "\(name)") {
                try fs.writeString("x", at: missing)
            }
            #expect(throws: FileSystemError.notFound(try ProjectPath("nothing")), "\(name)") {
                try fs.readFile(at: try ProjectPath("nothing"))
            }
            try fs.createDirectory(at: try ProjectPath("d"))
            #expect(throws: FileSystemError.alreadyExists(try ProjectPath("d")), "\(name)") {
                try fs.createDirectory(at: try ProjectPath("d"))
            }
            #expect(throws: FileSystemError.isADirectory(try ProjectPath("d")), "\(name)") {
                try fs.writeString("x", at: try ProjectPath("d"))
            }
            try fs.writeString("x", at: try ProjectPath("f"))
            #expect(throws: FileSystemError.notADirectory(try ProjectPath("f")), "\(name)") {
                try fs.contentsOfDirectory(at: try ProjectPath("f"))
            }
        }
    }

    @Test func inMemoryConvenienceInitCreatesParents() throws {
        let fs = try InMemoryFileSystem(files: ["Sources/App/main.swift": "print()"])
        #expect(try fs.readString(at: ProjectPath("Sources/App/main.swift")) == "print()")
        #expect(try fs.kind(of: ProjectPath("Sources/App")) == .directory)
    }
}
