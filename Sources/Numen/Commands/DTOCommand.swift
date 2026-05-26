import ArgumentParser
import Foundation
import Prompt

struct DTOCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dto",
        abstract: "Generate a data transfer object"
    )

    @Argument(help: "The name of the DTO (PascalCase, e.g. UserDTO)")
    var name: String

    @Option(name: .long, help: "Entity this DTO represents")
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

        let dtoName = name.applying(caseStyle: config.naming.caseStyle)
        print("🔮 Generating DTO: \(dtoName.cyan.bold)")
        print()

        let context = GenerationContext(
            name: dtoName,
            fields: parsedFields,
            entity: entity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try DTOGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
