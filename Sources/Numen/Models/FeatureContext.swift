import Foundation

enum FeatureComponent: String, CaseIterable {
    case entity
    case repository
    case usecases
    case dto
    case controller
    case routes
    case migration

    static func parse(_ value: String) -> FeatureComponent? {
        FeatureComponent(rawValue: value.lowercased())
    }
}

struct FeatureContext {
    let name: String
    let fields: [Field]
    let outputPath: String?
    let dryRun: Bool
    let skipComponents: Set<FeatureComponent>

    var entityName: String { name }
    var repositoryName: String { "\(name)Repository" }
    var controllerName: String { "\(name)Controller" }
    var dtoName: String { "\(name)DTO" }
    var migrationName: String { "Create\(name)" }

    func shouldSkip(_ component: FeatureComponent) -> Bool {
        skipComponents.contains(component)
    }

    init(
        name: String,
        fields: [Field] = [],
        outputPath: String? = nil,
        dryRun: Bool = false,
        skipComponents: Set<FeatureComponent> = []
    ) {
        self.name = name
        self.fields = fields
        self.outputPath = outputPath
        self.dryRun = dryRun
        self.skipComponents = skipComponents
    }

    func entityContext() -> GenerationContext {
        GenerationContext(
            name: entityName,
            fields: fields,
            outputPath: outputPath.map { "\($0)/Domain/Entities" },
            dryRun: dryRun
        )
    }

    func repositoryContext() -> GenerationContext {
        GenerationContext(
            name: repositoryName,
            fields: fields,
            entity: entityName,
            outputPath: outputPath.map { "\($0)/Domain/Repositories" },
            dryRun: dryRun
        )
    }

    func useCaseContext() -> GenerationContext {
        GenerationContext(
            name: name,
            fields: fields,
            entity: entityName,
            outputPath: outputPath.map { "\($0)/Application/UseCases" },
            dryRun: dryRun
        )
    }

    func dtoContext() -> GenerationContext {
        GenerationContext(
            name: dtoName,
            fields: fields,
            entity: entityName,
            outputPath: outputPath.map { "\($0)/Application/DTOs" },
            dryRun: dryRun
        )
    }

    func controllerContext() -> GenerationContext {
        GenerationContext(
            name: controllerName,
            fields: fields,
            entity: entityName,
            outputPath: outputPath.map { "\($0)/Presentation/Controllers" },
            dryRun: dryRun
        )
    }

    func routeContext() -> GenerationContext {
        GenerationContext(
            name: name,
            outputPath: outputPath.map { "\($0)/Presentation/Routes" },
            dryRun: dryRun
        )
    }

    func migrationContext() -> GenerationContext {
        GenerationContext(
            name: migrationName,
            fields: fields,
            entity: entityName,
            outputPath: outputPath.map { "\($0)/Infrastructure/Migrations" },
            dryRun: dryRun
        )
    }
}
