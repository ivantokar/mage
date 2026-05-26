import ArgumentParser
import Foundation
import Prompt

struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Generate JWT authentication scaffolding (User model, AuthController, tokens, middleware)"
    )

    @Flag(name: .long, help: "Dry run — show what would be generated")
    var dryRun: Bool = false

    func run() throws {
        print()

        guard ConfigLoader.isInitialized() else {
            print("❌ Not a Numen project. Run 'numen new <name>' to create one.".red)
            throw ExitCode.failure
        }

        let config = try ConfigLoader.load()

        print("🔮 Generating auth scaffolding...".magenta.bold)
        print()

        let context = GenerationContext(dryRun: dryRun)

        let generator = try AuthSetupGenerator(config: config)
        try generator.generate(context: context)
    }
}

extension GenerationContext {
    init(dryRun: Bool) {
        self.init(name: "Auth", dryRun: dryRun)
    }
}
