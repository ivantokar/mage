/// The structured outcome of a generation run.
public struct GenerationResult: Sendable, Equatable {
    public enum Change: Sendable, Equatable {
        case created
        case updated
        case unchanged
        case removed
    }

    public struct Entry: Sendable, Equatable {
        public var path: ProjectPath
        public var isDirectory: Bool
        public var change: Change

        public init(path: ProjectPath, isDirectory: Bool = false, change: Change) {
            self.path = path
            self.isDirectory = isDirectory
            self.change = change
        }
    }

    /// `true` when the changes were written; `false` for a dry run.
    public var applied: Bool
    public var entries: [Entry]
    /// Non-fatal diagnostics (warnings and notes). Failures are thrown, never stored here.
    public var diagnostics: [Diagnostic]

    public init(applied: Bool, entries: [Entry], diagnostics: [Diagnostic] = []) {
        self.applied = applied
        self.entries = entries
        self.diagnostics = diagnostics
    }

    public func paths(_ change: Change) -> [ProjectPath] {
        entries.filter { $0.change == change }.map(\.path)
    }

    public var created: [ProjectPath] { paths(.created) }
    public var updated: [ProjectPath] { paths(.updated) }
    public var unchanged: [ProjectPath] { paths(.unchanged) }
    public var removed: [ProjectPath] { paths(.removed) }

    /// `true` when nothing would change (or changed).
    public var isNoOp: Bool { entries.allSatisfy { $0.change == .unchanged } }
}
