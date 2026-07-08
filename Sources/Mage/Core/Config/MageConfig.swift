import Foundation

struct MageConfig: Codable {
    let version: String
    let framework: String
    let architecture: ArchitectureConfig
    let paths: PathsConfig
    let naming: NamingConfig
    let database: DatabaseConfig?

    struct ArchitectureConfig: Codable {
        let style: String
        let layers: [String]
    }

    struct PathsConfig: Codable {
        let sources: String
        let domain: String
        let application: String
        let infrastructure: String
        let persistence: String
        let interface: String
        let tests: String
    }

    struct NamingConfig: Codable {
        let repositorySuffix: String
        let serviceSuffix: String
        let useCaseSuffix: String
        let controllerSuffix: String
        let caseStyle: CaseStyle

        enum CaseStyle: String, Codable {
            case camelCase
            case PascalCase
            case snake_case
            case kebabCase = "kebab-case"
        }
    }

    struct DatabaseConfig: Codable {
        let type: DatabaseType

        enum DatabaseType: String, Codable {
            case postgres
            case mysql
            case sqlite
            case mongodb
        }
    }

    static let `default` = MageConfig(
        version: "1.0",
        framework: "vapor",
        architecture: ArchitectureConfig(
            style: "ddd",
            layers: ["domain", "application", "infrastructure", "interface"]
        ),
        paths: PathsConfig(
            sources: "Sources/App",
            domain: "Sources/App/Domain",
            application: "Sources/App/Application",
            infrastructure: "Sources/App/Infrastructure",
            persistence: "Sources/App/Infrastructure/Persistence/Fluent",
            interface: "Sources/App/Interface/HTTP",
            tests: "Tests/AppTests"
        ),
        naming: NamingConfig(
            repositorySuffix: "Repository",
            serviceSuffix: "Service",
            useCaseSuffix: "UseCase",
            controllerSuffix: "Controller",
            caseStyle: .PascalCase
        ),
        database: DatabaseConfig(type: .postgres)
    )
}
