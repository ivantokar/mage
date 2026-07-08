import ArgumentParser
import Foundation
import Prompt

struct RelationshipCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "relationship",
        abstract: "Generate a relationship migration between two entities"
    )

    @Argument(help: "The source entity (e.g. User)")
    var from: String

    @Argument(help: "The target entity (e.g. Post)")
    var to: String

    @Option(name: .long, help: "Relationship type: has-many, belongs-to, many-to-many")
    var type: String = "has-many"

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

        guard let relationshipType = RelationshipType(rawValue: type) else {
            print("❌ Invalid relationship type '\(type)'.".red)
            print("   Supported: has-many, belongs-to, many-to-many")
            throw ExitCode.failure
        }

        print("🔮 Generating relationship migration: \(from.cyan) → \(to.cyan) (\(type.yellow))")
        print()

        let context = GenerationContext(
            name: "\(from)\(to)",
            outputPath: output,
            dryRun: dryRun
        )

        let generator = try RelationshipMigrationGenerator(config: config)
        try generator.generate(
            context: context,
            fromEntity: from,
            toEntity: to,
            relationshipType: relationshipType
        )
    }
}
