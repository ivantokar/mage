import Foundation

struct NumenConfig: Codable {
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
        let presentation: String
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

    static let `default` = NumenConfig(
        version: "1.0",
        framework: "vapor",
        architecture: ArchitectureConfig(
            style: "ddd",
            layers: ["domain", "application", "infrastructure", "presentation"]
        ),
        paths: PathsConfig(
            sources: "Sources/App",
            domain: "Sources/App/Domain",
            application: "Sources/App/Application",
            infrastructure: "Sources/App/Infrastructure",
            presentation: "Sources/App/Presentation",
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
