import ArgumentParser
import Foundation
import Prompt

struct UseCaseCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "use-case",
        abstract: "Generate an application use case"
    )

    @Argument(help: "The name of the use case (PascalCase, e.g. CreateUserUseCase)")
    var name: String

    @Option(name: .long, help: "Entity this use case operates on")
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
            print("❌ Invalid name '\(name)'. Use PascalCase.".red)
            throw ExitCode.failure
        }

        print("🔮 Generating use case: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            fields: parsedFields,
            entity: entity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try UseCaseGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
