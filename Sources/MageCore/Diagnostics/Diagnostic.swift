/// Severity of a ``Diagnostic``. Ordered from least to most severe.
public enum DiagnosticSeverity: String, Sendable, Comparable, CaseIterable {
    case note
    case warning
    case error

    private var rank: Int {
        switch self {
        case .note: 0
        case .warning: 1
        case .error: 2
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

/// A stable, machine-readable identifier for a kind of diagnostic, for example
/// `generation.conflict.not-mage-owned`. Codes are part of Mage's public output:
/// tests, CI and `mage doctor` rely on them, so they must not be reworded casually.
public struct DiagnosticCode: Sendable, Hashable, RawRepresentable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

/// Where a diagnostic points. The path is relative to the project root so that
/// diagnostics are portable between machines.
public struct DiagnosticLocation: Sendable, Hashable {
    public var path: ProjectPath
    public var line: Int?
    public var column: Int?

    public init(path: ProjectPath, line: Int? = nil, column: Int? = nil) {
        self.path = path
        self.line = line
        self.column = column
    }
}

/// A structured message about the project or a generation run.
///
/// One model serves the CLI, `mage doctor`, tests and future tooling; presentation
/// is the job of the CLI layer, never of the code that produces a diagnostic.
public struct Diagnostic: Sendable, Hashable {
    public var code: DiagnosticCode
    public var severity: DiagnosticSeverity
    public var message: String
    public var location: DiagnosticLocation?
    public var suggestion: String?

    public init(
        code: DiagnosticCode,
        severity: DiagnosticSeverity,
        message: String,
        location: DiagnosticLocation? = nil,
        suggestion: String? = nil
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.location = location
        self.suggestion = suggestion
    }
}

extension Sequence where Element == Diagnostic {
    /// `true` when at least one diagnostic is an error.
    public var containsErrors: Bool { contains { $0.severity == .error } }
}
