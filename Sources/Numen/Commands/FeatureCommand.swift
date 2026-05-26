import ArgumentParser
import Foundation
import Prompt

struct FeatureCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "feature",
        abstract: "Generate a complete DDD feature (entity, DTO, repository, use cases, controller, routes, migration)"
    )

    @Argument(help: "The name of the feature (PascalCase, e.g. User, Product)")
    var name: String

    @Option(name: .long, help: "Fields in format 'name:Type,email:String,age:Int?'")
    var fields: String?

    @Option(name: [.short, .long], help: "Output base directory")
    var output: String?

    @Option(name: .long, help: "Skip components (comma-separated: entity,dto,repository,usecases,controller,routes,migration)")
    var skip: String?

    @Flag(name: .long, help: "Dry run — show what would be generated without creating files")
    var dryRun: Bool = false

    func run() throws {
        print()

        guard ConfigLoader.isInitialized() else {
            print("❌ Not a Numen project. Run 'numen new <name>' to create one.".red)
            throw ExitCode.failure
        }

        let config = try ConfigLoader.load()

        guard isValidName(name) else {
            print("❌ Invalid feature name '\(name)'. Use PascalCase (e.g. User, Product).".red)
            throw ExitCode.failure
        }

        var skipComponents: Set<FeatureComponent> = []
        if let skipString = skip {
            let parts = skipString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            for part in parts {
                if let component = FeatureComponent.parse(part) {
                    skipComponents.insert(component)
                } else {
                    print("⚠️  Unknown component '\(part)' — valid: \(FeatureComponent.allCases.map(\.rawValue).joined(separator: ", "))".yellow)
                }
            }
        }

        let parsedFields = Field.parseFields(fields)

        if !dryRun {
            print("🎨 Creating complete DDD feature: \(name.magenta.bold)")
            if !parsedFields.isEmpty {
                print("   Fields: \(parsedFields.map(\.name).joined(separator: ", "))")
            }
            if !skipComponents.isEmpty {
                print("   Skipping: \(skipComponents.map(\.rawValue).joined(separator: ", "))".dim)
            }
            print()
        }

        let context = FeatureContext(
            name: name,
            fields: parsedFields,
            outputPath: output,
            dryRun: dryRun,
            skipComponents: skipComponents
        )

        let generator = try FeatureGenerator(config: config)
        try generator.generate(context: context)

        if !dryRun {
            print()
            print("Next steps:".bold)
            print("  1. Register the migration in configure.swift:")
            print("     app.migrations.add(Create\(name)())")
            print("  2. Register routes in routes.swift:")
            print("     try app.register(collection: \(name)Controller())")
            print()
        }
    }

    private func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber }
    }
}
