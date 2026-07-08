import Foundation

struct GenerationContext {
    let name: String
    let fields: [Field]
    let aggregate: String?
    let entity: String?
    let useCase: String?
    let outputPath: String?
    let dryRun: Bool
    let metadata: [String: Any]

    init(
        name: String,
        fields: [Field] = [],
        aggregate: String? = nil,
        entity: String? = nil,
        useCase: String? = nil,
        outputPath: String? = nil,
        dryRun: Bool = false,
        metadata: [String: Any] = [:]
    ) {
        self.name = name
        self.fields = fields
        self.aggregate = aggregate
        self.entity = entity
        self.useCase = useCase
        self.outputPath = outputPath
        self.dryRun = dryRun
        self.metadata = metadata
    }
}

enum DDDComponentType {
    case entity
    case valueObject
    case aggregate
    case domainEvent
    case repository
    case service
    case useCase
    case dto
    case persistenceModel
    case repositoryImpl
    case controller
    case route
    case middleware
    case migration
    case seeder
    case test

    var directory: String {
        switch self {
        case .entity:           return "Entities"
        case .valueObject:      return "ValueObjects"
        case .aggregate:        return "Aggregates"
        case .domainEvent:      return "Events"
        case .repository:       return "Repositories"
        case .service:          return "Services"
        case .useCase:          return "UseCases"
        case .dto:              return "DTOs"
        case .persistenceModel: return "Models"
        case .repositoryImpl:   return "Repositories"
        case .controller:       return "Controllers"
        case .route:            return "Routes"
        case .middleware:       return "Middleware"
        case .migration:        return "Migrations"
        case .seeder:           return "Seeders"
        case .test:             return ""
        }
    }

    var layer: String {
        switch self {
        case .entity, .valueObject, .aggregate, .domainEvent, .repository, .service:
            return "domain"
        case .useCase, .dto:
            return "application"
        case .persistenceModel, .repositoryImpl, .migration, .seeder:
            return "persistence"
        case .controller, .route, .middleware:
            return "interface"
        case .test:
            return "tests"
        }
    }

    var description: String {
        switch self {
        case .entity:           return "Domain Entity"
        case .valueObject:      return "Value Object"
        case .aggregate:        return "Aggregate Root"
        case .domainEvent:      return "Domain Event"
        case .repository:       return "Repository Protocol"
        case .service:          return "Domain Service"
        case .useCase:          return "Use Case"
        case .dto:              return "Data Transfer Object"
        case .persistenceModel: return "Fluent Persistence Model"
        case .repositoryImpl:   return "Repository Implementation"
        case .controller:       return "HTTP Controller"
        case .route:            return "HTTP Route"
        case .middleware:       return "HTTP Middleware"
        case .migration:        return "Database Migration"
        case .seeder:           return "Database Seeder"
        case .test:             return "Test"
        }
    }
}
