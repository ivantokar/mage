import ArgumentParser
import Foundation
import MageCore
import Testing
@testable import MageCLI

final class BufferSink: OutputSink, @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""
    func write(_ text: String) { lock.lock(); buffer += text; lock.unlock() }
    var text: String { lock.lock(); defer { lock.unlock() }; return buffer }
}

@Suite struct CLITests {
    @Test func rootCommandParsesGlobalOptions() throws {
        let command = try #require(try MageCommand.parseAsRoot(["--verbose", "--no-color"]) as? MageCommand)
        #expect(command.global.verbose)
        #expect(command.global.noColor)
        #expect(command.global.verbosity == .verbose)
    }

    @Test func verboseAndQuietConflict() {
        #expect(throws: (any Error).self) { try MageCommand.parseAsRoot(["--verbose", "--quiet"]) }
    }

    @Test func unknownOptionsAreRejected() {
        #expect(throws: (any Error).self) { try MageCommand.parseAsRoot(["--nope"]) }
    }

    @Test func versionComesFromCore() {
        #expect(MageCommand.configuration.version == MageVersion.current)
    }

    @Test func diagnosticFormat() throws {
        let diagnostic = Diagnostic(
            code: DiagnosticCode("generation.conflict.not-mage-owned"), severity: .error,
            message: "'a.swift' is not a Mage-generated file.",
            location: DiagnosticLocation(path: try ProjectPath("Sources/a.swift"), line: 3, column: 7),
            suggestion: "Move it.")
        #expect(ConsoleReporter.format(diagnostic) == """
            error[generation.conflict.not-mage-owned]: 'a.swift' is not a Mage-generated file.
              --> Sources/a.swift:3:7
              = help: Move it.
            """)
    }

    @Test func generationResultsPrintDryRunAndAppliedWording() throws {
        let entries = [
            GenerationResult.Entry(path: try ProjectPath("Sources"), isDirectory: true, change: .created),
            GenerationResult.Entry(path: try ProjectPath("a.txt"), change: .updated),
            GenerationResult.Entry(path: try ProjectPath("b.txt"), change: .unchanged),
        ]
        for (applied, expected) in [(false, "would create  Sources/\nwould update  a.txt\n"), (true, "created  Sources/\nupdated  a.txt\n")] {
            let out = BufferSink()
            ConsoleReporter(out: out, err: BufferSink()).report(GenerationResult(applied: applied, entries: entries))
            #expect(out.text == expected)
        }
        let verbose = BufferSink()
        ConsoleReporter(out: verbose, err: BufferSink(), verbosity: .verbose).report(GenerationResult(applied: true, entries: entries))
        #expect(verbose.text.contains("unchanged  b.txt"))
    }

    @Test func quietHidesNotesAndResultsButKeepsErrors() throws {
        let out = BufferSink(), err = BufferSink()
        let reporter = ConsoleReporter(out: out, err: err, verbosity: .quiet)
        reporter.report([
            Diagnostic(code: DiagnosticCode("a"), severity: .note, message: "note"),
            Diagnostic(code: DiagnosticCode("b"), severity: .error, message: "boom"),
        ])
        reporter.report(GenerationResult(applied: true, entries: [.init(path: try ProjectPath("a"), change: .created)]))
        #expect(err.text == "error[b]: boom\n")
        #expect(out.text.isEmpty)
    }

    @Test func failuresAreReportedAsDiagnosticsWithFailingExit() throws {
        let err = BufferSink()
        #expect(throws: ExitCode.failure) {
            try reportingFailures(err: err) { throw MageError(code: DiagnosticCode("x.y"), message: "bad") }
        }
        #expect(err.text == "error[x.y]: bad\n")
    }
}
