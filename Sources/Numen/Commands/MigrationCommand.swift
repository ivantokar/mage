import ArgumentParser
import Foundation
import Prompt

struct MigrationCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migration",
        abstract: "Generate a Fluent migration"
    )

    @Argument(help: "The name of the migration (PascalCase, e.g. CreateUser)")
    var name: String

    @Option(name: .long, help: "Entity this migration is for")
    var entity: String?

    @Option(name: .long, help: "Fields in format 'name:Type'")
    var fields: String?

    @Option(name: [.short, .long], help: "Output directory")
    var output: String?

    @Flag(name: .long, help: "Dry run")
    var dryRun: Bool = false

    func run() throws {
        print()

        guard ConfigLoader.isInitialized() else {
            print("❌ Not a Numen project. Run 'numen new <name>' to create one.".red)
            throw ExitCode.failure
        }

        let config = try ConfigLoader.load()
        let parsedFields = Field.parseFields(fields)

        guard isValidName(name) else {
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. CreateUser, AddEmailToUser).".red)
            throw ExitCode.failure
        }

        print("🔮 Generating migration: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            fields: parsedFields,
            entity: entity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try MigrationGenerator(config: config)
        try generator.generate(context: context)

        if !dryRun {
            print()
            print("Register this migration in configure.swift:".bold)
            print("  app.migrations.add(\(name)())")
            print()
        }
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
