import ArgumentParser
import Foundation
import Prompt

struct ControllerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "controller",
        abstract: "Generate a Vapor route controller"
    )

    @Argument(help: "The name of the controller (PascalCase, e.g. UserController)")
    var name: String

    @Option(name: .long, help: "Entity this controller manages")
    var entity: String?

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

        guard isValidName(name) else {
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. UserController).".red)
            throw ExitCode.failure
        }

        let resolvedEntity = entity ?? name.replacingOccurrences(of: "Controller", with: "")

        print("🔮 Generating controller: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            entity: resolvedEntity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try ControllerGenerator(config: config)
        try generator.generate(context: context, entityName: resolvedEntity)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
