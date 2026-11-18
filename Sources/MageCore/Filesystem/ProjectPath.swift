/// A normalized path relative to a project root.
///
/// Plans, manifests and diagnostics use `ProjectPath` rather than absolute paths so
/// that they are portable and cannot escape the project root. A path never starts
/// with `/`, never contains `.`, `..` or empty components, and always uses `/` as the
/// separator. The empty path is the project root itself.
public struct ProjectPath: Sendable, Hashable, Comparable, CustomStringConvertible, Codable {
    public let components: [String]

    /// The project root.
    public static let root = ProjectPath(uncheckedComponents: [])

    private init(uncheckedComponents: [String]) {
        self.components = uncheckedComponents
    }

    /// Creates a path from a `/`-separated string. Throws when the string is absolute,
    /// escapes the root, or contains empty, `.` or `..` components.
    public init(_ string: String) throws {
        if string.isEmpty { self = .root; return }
        guard !string.hasPrefix("/"), !string.contains("\\"), !string.contains("\0") else {
            throw ProjectPath.invalid(string, "must be a relative, `/`-separated path")
        }
        let parts = string.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        for part in parts where part.isEmpty || part == "." || part == ".." {
            throw ProjectPath.invalid(string, "contains an empty, `.` or `..` component")
        }
        self.init(uncheckedComponents: parts)
    }

    public init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        do { try self.init(string) } catch let error as MageError {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: error.description))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public var isRoot: Bool { components.isEmpty }
    public var lastComponent: String? { components.last }

    /// The containing directory, or `nil` for the root.
    public var parent: ProjectPath? {
        isRoot ? nil : ProjectPath(uncheckedComponents: Array(components.dropLast()))
    }

    /// All ancestors from the outermost directory below the root down to the parent.
    public var ancestors: [ProjectPath] {
        guard components.count > 1 else { return [] }
        return (1..<components.count).map { ProjectPath(uncheckedComponents: Array(components.prefix($0))) }
    }

    /// Appends a path (or a single component) to this one.
    public func appending(_ relative: String) throws -> ProjectPath {
        let tail = try ProjectPath(relative)
        return ProjectPath(uncheckedComponents: components + tail.components)
    }

    public func hasPrefix(_ other: ProjectPath) -> Bool {
        components.starts(with: other.components)
    }

    public var description: String { components.joined(separator: "/") }

    public static func < (lhs: ProjectPath, rhs: ProjectPath) -> Bool {
        lhs.description < rhs.description
    }

    private static func invalid(_ string: String, _ reason: String) -> MageError {
        MageError(
            code: .invalidProjectPath,
            message: "Invalid project path '\(string)': \(reason).")
    }
}

extension DiagnosticCode {
    public static let invalidProjectPath = DiagnosticCode("path.invalid")
}
