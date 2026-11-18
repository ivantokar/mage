import MageCore

/// Where console text goes. Injected so output is testable.
public protocol OutputSink: Sendable {
    func write(_ text: String)
}

/// Turns structured diagnostics and generation results into console text.
///
/// Core produces data; this is the only place that decides how it looks.
public struct ConsoleReporter: Sendable {
    public enum Verbosity: Sendable { case quiet, normal, verbose }

    private let out: any OutputSink
    private let err: any OutputSink
    private let verbosity: Verbosity

    public init(out: any OutputSink, err: any OutputSink, verbosity: Verbosity = .normal) {
        self.out = out
        self.err = err
        self.verbosity = verbosity
    }

    public func report(_ diagnostics: [Diagnostic]) {
        for diagnostic in diagnostics {
            if verbosity == .quiet, diagnostic.severity < .warning { continue }
            err.write(Self.format(diagnostic) + "\n")
        }
    }

    public func report(_ result: GenerationResult) {
        report(result.diagnostics)
        guard verbosity != .quiet else { return }
        let applied = result.applied
        for entry in result.entries {
            let name = entry.isDirectory ? "\(entry.path)/" : entry.path.description
            switch entry.change {
            case .created: out.write("\(applied ? "created" : "would create")  \(name)\n")
            case .updated: out.write("\(applied ? "updated" : "would update")  \(name)\n")
            case .removed: out.write("\(applied ? "removed" : "would remove")  \(name)\n")
            case .unchanged: if verbosity == .verbose { out.write("unchanged  \(name)\n") }
            }
        }
        if result.isNoOp { out.write("Nothing to do.\n") }
    }

    public static func format(_ diagnostic: Diagnostic) -> String {
        var text = "\(diagnostic.severity.rawValue)[\(diagnostic.code)]: \(diagnostic.message)"
        if let location = diagnostic.location {
            text += "\n  --> \(location.path)"
            if let line = location.line {
                text += ":\(line)"
                if let column = location.column { text += ":\(column)" }
            }
        }
        if let suggestion = diagnostic.suggestion { text += "\n  = help: \(suggestion)" }
        return text
    }
}
