import ArgumentParser
import Foundation
import Prompt

struct MiddlewareCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "middleware",
        abstract: "Generate a Vapor middleware"
    )

    @Argument(help: "The name of the middleware (PascalCase, e.g. AuthMiddleware)")
    var name: String

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
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. AuthMiddleware).".red)
            throw ExitCode.failure
        }

        let middlewareName = name.applying(caseStyle: config.naming.caseStyle)
        print("🔮 Generating middleware: \(middlewareName.cyan.bold)")
        print()

        let context = GenerationContext(
            name: middlewareName,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try MiddlewareGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
