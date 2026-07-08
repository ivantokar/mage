import ArgumentParser
import Foundation
import Prompt

struct DocsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "docs",
        abstract: "Generate API documentation scaffolding"
    )

    @Argument(help: "Project name for the docs (defaults to directory name)")
    var name: String?

    @Flag(name: .long, help: "Dry run")
    var dryRun: Bool = false

    func run() throws {
        print()

        guard ConfigLoader.isInitialized() else {
            print("❌ Not a Mage project. Run 'mage new <name>' to create one.".red)
            throw ExitCode.failure
        }

        let config = try ConfigLoader.load()
        let projectName = name ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent

        print("🔮 Generating docs scaffolding for: \(projectName.cyan.bold)")
        print()

        let context = GenerationContext(
            name: projectName,
            dryRun: dryRun
        )

        let generator = try DocsGenerator(config: config)
        try generator.generate(context: context)
    }
}
