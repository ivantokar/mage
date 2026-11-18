import Foundation

/// A ``FileSystem`` that lives in memory. Used by tests and by dry-run inspection.
public final class InMemoryFileSystem: FileSystem, @unchecked Sendable {
    private struct State {
        var directories: Set<ProjectPath> = [.root]
        var files: [ProjectPath: Data] = [:]
    }

    private let lock = NSLock()
    private var state = State()

    private func withLock<T>(_ body: (inout State) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }

    public init() {}

    /// Creates a file system pre-populated with files. Missing parent directories are created.
    public convenience init(files: [String: String]) throws {
        self.init()
        for (name, contents) in files {
            let path = try ProjectPath(name)
            for ancestor in path.ancestors where try !exists(ancestor) { try createDirectory(at: ancestor) }
            try writeString(contents, at: path)
        }
    }

    public func kind(of path: ProjectPath) throws -> FileKind? {
        withLock { s in
            if s.directories.contains(path) { return .directory }
            if s.files[path] != nil { return .file }
            return nil
        }
    }

    public func readFile(at path: ProjectPath) throws -> Data {
        try withLock { s in
            if s.directories.contains(path) { throw FileSystemError.isADirectory(path) }
            guard let data = s.files[path] else { throw FileSystemError.notFound(path) }
            return data
        }
    }

    public func writeFile(_ data: Data, at path: ProjectPath) throws {
        try withLock { s in
            guard let parent = path.parent else { throw FileSystemError.isADirectory(path) }
            guard s.directories.contains(parent) else {
                throw s.files[parent] != nil ? FileSystemError.notADirectory(parent) : FileSystemError.notFound(parent)
            }
            if s.directories.contains(path) { throw FileSystemError.isADirectory(path) }
            s.files[path] = data
        }
    }

    public func createDirectory(at path: ProjectPath) throws {
        try withLock { s in
            if s.directories.contains(path) || s.files[path] != nil { throw FileSystemError.alreadyExists(path) }
            guard let parent = path.parent, s.directories.contains(parent) else {
                throw FileSystemError.notFound(path.parent ?? path)
            }
            s.directories.insert(path)
        }
    }

    public func removeFile(at path: ProjectPath) throws {
        try withLock { s in
            if s.directories.contains(path) { throw FileSystemError.isADirectory(path) }
            guard s.files.removeValue(forKey: path) != nil else { throw FileSystemError.notFound(path) }
        }
    }

    public func removeDirectory(at path: ProjectPath) throws {
        try withLock { s in
            if s.files[path] != nil { throw FileSystemError.notADirectory(path) }
            guard s.directories.contains(path), !path.isRoot else { throw FileSystemError.notFound(path) }
            let hasChildren = s.directories.contains { $0 != path && $0.hasPrefix(path) }
                || s.files.keys.contains { $0.hasPrefix(path) }
            if hasChildren { throw FileSystemError.directoryNotEmpty(path) }
            s.directories.remove(path)
        }
    }

    public func contentsOfDirectory(at path: ProjectPath) throws -> [ProjectPath] {
        try withLock { s in
            if s.files[path] != nil { throw FileSystemError.notADirectory(path) }
            guard s.directories.contains(path) else { throw FileSystemError.notFound(path) }
            let depth = path.components.count + 1
            let children = s.directories.filter { $0.components.count == depth && $0.hasPrefix(path) }
                + s.files.keys.filter { $0.components.count == depth && $0.hasPrefix(path) }
            return children.sorted()
        }
    }
}
