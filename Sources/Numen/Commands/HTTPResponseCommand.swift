import ArgumentParser
import Foundation
import Prompt

struct HTTPResponseCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "http-response",
        abstract: "Generate an HTTP response type in Interface/HTTP/Responses"
    )

    @Argument(help: "The entity name (PascalCase, e.g. Asset — generates AssetResponse)")
    var name: String

    @Option(name: .long, help: "Fields in format 'name:Type,status:String'")
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

        print("🔮 Generating HTTP response: \(name)Response".cyan.bold)
        print()

        let context = GenerationContext(
            name: name,
            fields: parsedFields,
            entity: name,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try HTTPResponseGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
