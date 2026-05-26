import ArgumentParser
import Foundation
import Prompt

struct EntityCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "entity",
        abstract: "Generate a domain entity"
    )

    @Argument(help: "The name of the entity (PascalCase)")
    var name: String

    @Option(name: .long, help: "Aggregate this entity belongs to")
    var aggregate: String?

    @Option(name: .long, help: "Fields in format 'name:Type,email:String,age:Int?'")
    var fields: String?

    @Option(name: [.short, .long], help: "Output directory (relative to project root)")
    var output: String?

    @Flag(name: .long, help: "Dry run — show what would be generated without creating files")
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
            print("❌ Invalid entity name '\(name)'. Use PascalCase (e.g. User, OrderItem).".red)
            throw ExitCode.failure
        }

        let entityName = name.applying(caseStyle: config.naming.caseStyle)
        print("🔮 Generating entity: \(entityName.cyan.bold)")
        if let aggregate { print("   Aggregate: \(aggregate.yellow)") }
        if !parsedFields.isEmpty { print("   Fields: \(parsedFields.count)") }
        print()

        let context = GenerationContext(
            name: entityName,
            fields: parsedFields,
            aggregate: aggregate,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try EntityGenerator(config: config)
        try generator.generate(context: context)

        if !dryRun {
            print()
            print("Next steps:".bold)
            print("  numen migration Create\(entityName) --entity \(entityName)")
            print("  numen repository \(entityName)Repository --entity \(entityName)")
            print()
        }
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
