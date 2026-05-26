import Foundation
import Prompt

class FeatureGenerator {
    private let config: NumenConfig
    private let entityGenerator: EntityGenerator
    private let repositoryGenerator: RepositoryGenerator
    private let crudUseCasesGenerator: CRUDUseCasesGenerator
    private let dtoGenerator: DTOGenerator
    private let controllerGenerator: ControllerGenerator
    private let routeGenerator: RouteGenerator
    private let migrationGenerator: MigrationGenerator

    init(config: NumenConfig) throws {
        self.config = config
        self.entityGenerator = try EntityGenerator(config: config)
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
            print("   Generating entity...".dim)
            try entityGenerator.generate(context: context.entityContext())
            generatedCount += 1
            print()
        }

        if !context.shouldSkip(.dto) {
            print("   Generating DTO...".dim)
            try dtoGenerator.generate(context: context.dtoContext())
            generatedCount += 1
            print()
        }

        if !context.shouldSkip(.repository) {
            print("   Generating repository...".dim)
            try repositoryGenerator.generate(context: context.repositoryContext())
            generatedCount += 2
            print()
        }

        if !context.shouldSkip(.usecases) {
            print("   Generating CRUD use cases...".dim)
            try crudUseCasesGenerator.generate(
                context: context.useCaseContext(),
                entityName: context.entityName,
                repositoryName: context.repositoryName,
                dtoName: context.dtoName
            )
            generatedCount += 5
            print()
        }

        if !context.shouldSkip(.controller) {
            print("   Generating controller...".dim)
            try controllerGenerator.generate(
                context: context.controllerContext(),
                entityName: context.entityName
            )
            generatedCount += 1
            print()
        }

        if !context.shouldSkip(.routes) {
            print("   Generating routes...".dim)
            try routeGenerator.generate(
                context: context.routeContext(),
                entityName: context.entityName,
                controllerName: context.controllerName
            )
            generatedCount += 1
            print()
        }

        if !context.shouldSkip(.migration) {
            print("   Generating migration...".dim)
            try migrationGenerator.generate(context: context.migrationContext())
            generatedCount += 1
            print()
        }

        print("✅ Feature '\(context.name)' generated successfully!".green.bold)
        print("   Created \(generatedCount) file(s)".dim)
    }
}
