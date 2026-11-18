import ArgumentParser
import MageCore

/// The `mage` root command.
///
/// vNext commands (`init`, `doctor`, ...) are added by later roadmap phases. There is no
/// compatibility with the prototype command set.
public struct MageCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mage",
        abstract: "Initialize, generate, integrate and validate Clean Layered DDD architecture in existing server-side Swift projects.",
        version: MageVersion.current,
        subcommands: []
    )

    @OptionGroup public var global: GlobalOptions

    public init() {}

    public func run() throws {
        print(Self.helpMessage())
    }
}

/// Runs a command body and presents a ``MageError`` as diagnostics with a failing exit status.
///
/// Subcommands wrap their work in this so failures are always reported the same way.
public func reportingFailures(
    verbosity: ConsoleReporter.Verbosity = .normal,
    err: any OutputSink = StandardError(),
    _ body: () throws -> Void
) throws {
    do {
        try body()
    } catch let error as MageError {
        ConsoleReporter(out: StandardOutput(), err: err, verbosity: verbosity).report(error.diagnostics)
        throw ExitCode.failure
    }
}
