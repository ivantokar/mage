import Foundation

public enum FileKind: Sendable, Equatable {
    case file
    case directory
}

/// The narrow filesystem boundary used by Mage.
///
/// A `FileSystem` is rooted at one directory and addresses everything through
/// ``ProjectPath``, so generation logic can neither escape the project nor depend on
/// `FileManager.default`. Implementations: ``LocalFileSystem`` and the in-memory
/// ``InMemoryFileSystem`` used by tests and dry runs.
public protocol FileSystem: Sendable {
    /// The kind of item at `path`, or `nil` when nothing exists there.
    func kind(of path: ProjectPath) throws -> FileKind?
    func readFile(at path: ProjectPath) throws -> Data
    /// Creates or replaces a file. The parent directory must already exist.
    func writeFile(_ data: Data, at path: ProjectPath) throws
    /// Creates one directory. The parent directory must already exist.
    func createDirectory(at path: ProjectPath) throws
    func removeFile(at path: ProjectPath) throws
    /// Removes an empty directory.
    func removeDirectory(at path: ProjectPath) throws
    /// Direct children of a directory, sorted by path.
    func contentsOfDirectory(at path: ProjectPath) throws -> [ProjectPath]
}

extension FileSystem {
    public func exists(_ path: ProjectPath) throws -> Bool { try kind(of: path) != nil }

    /// Reads a UTF-8 text file.
    public func readString(at path: ProjectPath) throws -> String {
        let data = try readFile(at: path)
        guard let string = String(data: data, encoding: .utf8) else {
            throw FileSystemError.notUTF8(path)
        }
        return string
    }

    public func writeString(_ string: String, at path: ProjectPath) throws {
        try writeFile(Data(string.utf8), at: path)
    }
}

public enum FileSystemError: Error, Sendable, Equatable, CustomStringConvertible {
    case notFound(ProjectPath)
    case alreadyExists(ProjectPath)
    case notADirectory(ProjectPath)
    case isADirectory(ProjectPath)
    case directoryNotEmpty(ProjectPath)
    case notUTF8(ProjectPath)
    case io(ProjectPath, String)

    public var description: String {
        switch self {
        case .notFound(let p): "'\(p)' does not exist."
        case .alreadyExists(let p): "'\(p)' already exists."
        case .notADirectory(let p): "'\(p)' is not a directory."
        case .isADirectory(let p): "'\(p)' is a directory."
        case .directoryNotEmpty(let p): "Directory '\(p)' is not empty."
        case .notUTF8(let p): "'\(p)' is not valid UTF-8."
        case .io(let p, let message): "I/O error at '\(p)': \(message)"
        }
    }
}
