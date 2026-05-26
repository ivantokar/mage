import ArgumentParser
import Foundation
import Prompt

struct ServiceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "service",
        abstract: "Generate a domain service"
    )

    @Argument(help: "The name of the service (PascalCase)")
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
            print("❌ Invalid name '\(name)'. Use PascalCase (e.g. UserService, PaymentService).".red)
            throw ExitCode.failure
        }

        print("🔮 Generating service: \(name.cyan.bold)")
        print()

        let context = GenerationContext(
            name: name,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try ServiceGenerator(config: config)
        try generator.generate(context: context)
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
