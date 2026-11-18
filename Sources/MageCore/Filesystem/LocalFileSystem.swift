import Foundation

/// A ``FileSystem`` backed by a directory on disk.
public struct LocalFileSystem: FileSystem {
    public let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    private func url(_ path: ProjectPath) -> URL {
        path.components.reduce(root) { $0.appendingPathComponent($1) }
    }

    public func kind(of path: ProjectPath) throws -> FileKind? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url(path).path, isDirectory: &isDirectory) else {
            return nil
        }
        return isDirectory.boolValue ? .directory : .file
    }

    public func readFile(at path: ProjectPath) throws -> Data {
        switch try kind(of: path) {
        case nil: throw FileSystemError.notFound(path)
        case .directory: throw FileSystemError.isADirectory(path)
        case .file: break
        }
        return try wrap(path) { try Data(contentsOf: url(path)) }
    }

    public func writeFile(_ data: Data, at path: ProjectPath) throws {
        if let parent = path.parent {
            guard try kind(of: parent) == .directory else {
                throw try kind(of: parent) == nil ? FileSystemError.notFound(parent) : FileSystemError.notADirectory(parent)
            }
        }
        if try kind(of: path) == .directory { throw FileSystemError.isADirectory(path) }
        try wrap(path) { try data.write(to: url(path), options: .atomic) }
    }

    public func createDirectory(at path: ProjectPath) throws {
        if try kind(of: path) != nil { throw FileSystemError.alreadyExists(path) }
        if let parent = path.parent, try kind(of: parent) != .directory {
            throw FileSystemError.notFound(parent)
        }
        try wrap(path) {
            try FileManager.default.createDirectory(at: url(path), withIntermediateDirectories: false)
        }
    }

    public func removeFile(at path: ProjectPath) throws {
        switch try kind(of: path) {
        case nil: throw FileSystemError.notFound(path)
        case .directory: throw FileSystemError.isADirectory(path)
        case .file: break
        }
        try wrap(path) { try FileManager.default.removeItem(at: url(path)) }
    }

    public func removeDirectory(at path: ProjectPath) throws {
        switch try kind(of: path) {
        case nil: throw FileSystemError.notFound(path)
        case .file: throw FileSystemError.notADirectory(path)
        case .directory: break
        }
        guard try contentsOfDirectory(at: path).isEmpty else { throw FileSystemError.directoryNotEmpty(path) }
        try wrap(path) { try FileManager.default.removeItem(at: url(path)) }
    }

    public func contentsOfDirectory(at path: ProjectPath) throws -> [ProjectPath] {
        switch try kind(of: path) {
        case nil: throw FileSystemError.notFound(path)
        case .file: throw FileSystemError.notADirectory(path)
        case .directory: break
        }
        let names = try wrap(path) { try FileManager.default.contentsOfDirectory(atPath: url(path).path) }
        return try names.sorted().map { try path.appending($0) }
    }

    private func wrap<T>(_ path: ProjectPath, _ body: () throws -> T) throws -> T {
        do { return try body() } catch let error as FileSystemError {
            throw error
        } catch {
            throw FileSystemError.io(path, error.localizedDescription)
        }
    }
}
