/// The error thrown when a Mage operation fails.
///
/// Failures are errors, never successful results that hide a problem. A
/// `MageError` always carries at least one error-severity diagnostic.
public struct MageError: Error, Sendable, Equatable {
    public var diagnostics: [Diagnostic]

    public init(diagnostics: [Diagnostic]) {
        precondition(!diagnostics.isEmpty, "MageError needs at least one diagnostic")
        self.diagnostics = diagnostics
    }

    public init(_ diagnostic: Diagnostic) {
        self.init(diagnostics: [diagnostic])
    }

    public init(code: DiagnosticCode, message: String, location: DiagnosticLocation? = nil, suggestion: String? = nil) {
        self.init(Diagnostic(code: code, severity: .error, message: message, location: location, suggestion: suggestion))
    }
}

extension MageError: CustomStringConvertible {
    public var description: String { diagnostics.map(\.message).joined(separator: "\n") }
}
