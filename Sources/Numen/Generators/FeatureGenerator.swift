import Foundation
import Prompt

class FeatureGenerator {
    private let config: NumenConfig
    private let aggregateRootGenerator: AggregateRootGenerator
    private let fluentModelGenerator: FluentModelGenerator
    private let repositoryGenerator: RepositoryGenerator
    private let crudUseCasesGenerator: CRUDUseCasesGenerator
    private let dtoGenerator: DTOGenerator
    private let controllerGenerator: ControllerGenerator
    private let routeGenerator: RouteGenerator
    private let migrationGenerator: MigrationGenerator

    init(config: NumenConfig) throws {
        self.config = config
        self.aggregateRootGenerator = try AggregateRootGenerator(config: config)
        self.fluentModelGenerator = try FluentModelGenerator(config: config)
        self.repositoryGenerator = try RepositoryGenerator(config: config)
        self.crudUseCasesGenerator = try CRUDUseCasesGenerator(config: config)
        self.dtoGenerator = try DTOGenerator(config: config)
        self.controllerGenerator = try ControllerGenerator(config: config)
        self.routeGenerator = try RouteGenerator(config: config)
        self.migrationGenerator = try MigrationGenerator(config: config)
    }

    func generate(context: FeatureContext) throws {
        print("🔮 Generating complete feature: \(context.name.cyan.bold)")
        print()

        if context.dryRun {
            print("Dry run — would generate:".yellow)
            print()
        }

        var generatedCount = 0

        if !context.shouldSkip(.entity) {
            print("   Generating aggregate root...".dim)
            generatedCount += attempt { try self.aggregateRootGenerator.generate(context: context.aggregateContext()) }
            print()
            print("   Generating Fluent model...".dim)
            generatedCount += attempt { try self.fluentModelGenerator.generate(context: context.persistenceModelContext()) }
            print()
        }

        if !context.shouldSkip(.dto) {
            print("   Generating DTO...".dim)
            generatedCount += attempt { try self.dtoGenerator.generate(context: context.dtoContext()) }
            print()
        }

        if !context.shouldSkip(.repository) {
            print("   Generating repository...".dim)
            generatedCount += attempt(count: 2) { try self.repositoryGenerator.generate(context: context.repositoryContext()) }
            print()
        }

        if !context.shouldSkip(.usecases) {
            print("   Generating CRUD use cases...".dim)
            generatedCount += attempt(count: 5) {
                try self.crudUseCasesGenerator.generate(
                    context: context.useCaseContext(),
                    entityName: context.entityName,
                    repositoryName: context.repositoryName,
                    dtoName: context.dtoName
                )
            }
            print()
        }

        if !context.shouldSkip(.controller) {
            print("   Generating controller...".dim)
            generatedCount += attempt { try self.controllerGenerator.generate(context: context.controllerContext(), entityName: context.entityName) }
            print()
        }

        if !context.shouldSkip(.routes) {
            print("   Generating routes...".dim)
            generatedCount += attempt {
                try self.routeGenerator.generate(context: context.routeContext(), entityName: context.entityName, controllerName: context.controllerName)
            }
            print()
        }

        if !context.shouldSkip(.migration) {
            print("   Generating migration...".dim)
            generatedCount += attempt { try self.migrationGenerator.generate(context: context.migrationContext()) }
            print()
        }

        print("✅ Feature '\(context.name)' generated successfully!".green.bold)
        print("   Created \(generatedCount) file(s)".dim)
    }

    @discardableResult
    private func attempt(count: Int = 1, block: () throws -> Void) -> Int {
        do {
            try block()
            return count
        } catch GeneratorError.fileAlreadyExists(let path) {
            let rel = path.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
            print("  ⚠️  Skipped (already exists): \(rel)".yellow)
            return 0
        } catch {
            print("  ❌ \(error.localizedDescription)".red)
            return 0
        }
    }
}
