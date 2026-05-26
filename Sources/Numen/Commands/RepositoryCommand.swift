import ArgumentParser
import Foundation
import Prompt

struct RepositoryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "repository",
        abstract: "Generate a repository protocol and Fluent implementation"
    )

    @Argument(help: "The name of the repository (PascalCase, e.g. UserRepository)")
    var name: String

    @Option(name: .long, help: "Entity this repository manages")
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
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. UserRepository).".red)
            throw ExitCode.failure
        }

        let repoName = name.applying(caseStyle: config.naming.caseStyle)
        let resolvedEntity = entity ?? repoName.replacingOccurrences(of: "Repository", with: "")

        print("🔮 Generating repository: \(repoName.cyan.bold)")
        print("   Entity: \(resolvedEntity.yellow)")
        print()

        let context = GenerationContext(
            name: repoName,
            fields: parsedFields,
            entity: resolvedEntity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try RepositoryGenerator(config: config)
        try generator.generate(context: context)

        if !dryRun {
            print()
            print("Next steps:".bold)
            print("  Register FluentUserRepository in your configure.swift or service container")
            print()
        }
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
