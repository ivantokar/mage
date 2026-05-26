import ArgumentParser
import Foundation
import Prompt

struct SeederCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "seeder",
        abstract: "Generate a database seeder"
    )

    @Argument(help: "The name of the seeder (PascalCase, e.g. UserSeeder)")
    var name: String

    @Option(name: .long, help: "Entity this seeder populates")
    var entity: String?

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

        guard isValidName(name) else {
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. UserSeeder).".red)
            throw ExitCode.failure
        }

        let resolvedEntity = entity ?? name.replacingOccurrences(of: "Seeder", with: "")

        print("🔮 Generating seeder: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            entity: resolvedEntity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try SeederGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
