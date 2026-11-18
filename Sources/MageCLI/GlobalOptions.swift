import ArgumentParser

/// Options accepted by every Mage command.
public struct GlobalOptions: ParsableArguments {
    @Flag(name: [.short, .long], help: "Show unchanged files and extra detail.")
    public var verbose = false

    @Flag(name: [.short, .long], help: "Only print warnings and errors.")
    public var quiet = false

    @Flag(name: .customLong("no-color"), help: "Disable colored output.")
    public var noColor = false

    public init() {}

    public mutating func validate() throws {
        if verbose && quiet {
            throw ValidationError("--verbose and --quiet cannot be used together.")
        }
    }

    public var verbosity: ConsoleReporter.Verbosity {
        quiet ? .quiet : (verbose ? .verbose : .normal)
    }
}

/// Options shared by commands that produce a ``GenerationPlan``.
public struct GenerationOptions: ParsableArguments {
    @Flag(help: "Show what would change without writing any files.")
    public var dryRun = false

    @Flag(help: "Never prompt; fail clearly when required information is missing.")
    public var nonInteractive = false

    public init() {}
}
