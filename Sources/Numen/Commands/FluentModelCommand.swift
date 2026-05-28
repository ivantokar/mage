import ArgumentParser
import Foundation
import Prompt

struct FluentModelCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fluent-model",
        abstract: "Generate a Fluent persistence model in Infrastructure"
    )

    @Argument(help: "The domain entity/aggregate name (PascalCase, e.g. Asset — generates AssetModel)")
    var name: String

    @Option(name: .long, help: "Fields in format 'name:Type,status:String,active:Bool?'")
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
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. Asset, WorkOrder).".red)
            throw ExitCode.failure
        }

        print("🔮 Generating Fluent model: \(name)Model".cyan.bold)
        print("   Location: Infrastructure/Persistence/Fluent/Models")
        print()

        let context = GenerationContext(
            name: name,
            fields: parsedFields,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try FluentModelGenerator(config: config)
        try generator.generate(context: context)

        if !dryRun {
            print()
            print("Next steps:".bold)
            print("  numen migration Create\(name) --entity \(name)")
            print()
        }
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
