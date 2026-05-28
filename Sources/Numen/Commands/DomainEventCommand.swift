import ArgumentParser
import Foundation
import Prompt

struct DomainEventCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "domain-event",
        abstract: "Generate a domain event"
    )

    @Argument(help: "The name of the domain event (PascalCase)")
    var name: String

    @Option(name: .long, help: "Aggregate this event belongs to")
    var aggregate: String?

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
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. UserCreated, OrderPlaced).".red)
            throw ExitCode.failure
        }

        print("🔮 Generating domain event: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            fields: parsedFields,
            aggregate: aggregate,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try DomainEventGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
