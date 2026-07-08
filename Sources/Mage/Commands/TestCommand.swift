import ArgumentParser
import Foundation
import Prompt

struct TestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Generate a test file for a component"
    )

    @Argument(help: "The name of the component to test")
    var name: String

    @Option(name: .long, help: "Type of test: entity, repository, use-case, controller, feature")
    var type: String = "feature"

    @Option(name: .long, help: "Entity name (for repository/use-case tests)")
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

        guard let testType = TestTargetType(rawValue: type) else {
            print("❌ Invalid test type '\(type)'.".red)
            print("   Supported: entity, repository, use-case, controller, feature")
            throw ExitCode.failure
        }

        print("🔮 Generating test: \(name.cyan.bold) (\(type))")
        print()

        let context = GenerationContext(
            name: name,
            entity: entity,
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try TestGenerator(config: config)
        try generator.generate(context: context, targetType: testType)
    }
}
