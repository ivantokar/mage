import ArgumentParser
import Foundation
import Prompt

struct RouteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "route",
        abstract: "Generate a route collection"
    )

    @Argument(help: "The name of the route/resource (PascalCase, e.g. User)")
    var name: String

    @Option(name: .long, help: "Controller to use")
    var controller: String?

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
            print("❌ Invalid name '\(name)'. Use PascalCase.".red)
            throw ExitCode.failure
        }

        let routeName = name.applying(caseStyle: config.naming.caseStyle)
        let resolvedController = controller ?? "\(routeName)Controller"

        print("🔮 Generating route: \(routeName.cyan.bold)")
        print()

        let context = GenerationContext(
            name: routeName,
            useCase: resolvedController,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try RouteGenerator(config: config)
        try generator.generate(context: context, entityName: routeName, controllerName: resolvedController)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
