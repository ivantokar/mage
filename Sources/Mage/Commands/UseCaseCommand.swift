import ArgumentParser
import Foundation
import Prompt

struct UseCaseCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "use-case",
        abstract: "Generate an application use case"
    )

    @Argument(help: "The name of the use case (PascalCase, e.g. CreateUserUseCase) OR entity name when --crud is used")
    var name: String

    @Option(name: .long, help: "Entity this use case operates on")
    var entity: String?

    @Option(name: .long, help: "Repository name (for --crud)")
    var repository: String?

    @Option(name: .long, help: "DTO name (for --crud)")
    var dto: String?

    @Option(name: .long, help: "Fields in format 'name:Type'")
    var fields: String?

    @Flag(name: .long, help: "Generate all 5 CRUD use cases (Create/GetById/GetAll/Update/Delete)")
    var crud: Bool = false

    @Option(name: [.short, .long], help: "Output directory")
    var output: String?

    @Flag(name: .long, help: "Dry run")
    var dryRun: Bool = false

    func run() throws {
        print()

        guard ConfigLoader.isInitialized() else {
            print("❌ Not a Mage project. Run 'mage new <name>' to create one.".red)
            throw ExitCode.failure
        }

        let config = try ConfigLoader.load()
        let parsedFields = Field.parseFields(fields)

        guard isValidName(name) else {
            print("❌ Invalid name '\(name)'. Use PascalCase.".red)
            throw ExitCode.failure
        }

        if crud {
            let entityName = entity ?? name
            let repositoryName = repository ?? "\(entityName)Repository"
            let dtoName = dto ?? "\(entityName)DTO"

            print("🔮 Generating CRUD use cases for: \(entityName.cyan.bold)")
            print()

            let context = GenerationContext(
                name: entityName,
                fields: parsedFields,
                entity: entityName,
                outputPath: output,
                dryRun: dryRun
            )

            let generator = try CRUDUseCasesGenerator(config: config)
            try generator.generate(
                context: context,
                entityName: entityName,
                repositoryName: repositoryName,
                dtoName: dtoName
            )
        } else {
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
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
