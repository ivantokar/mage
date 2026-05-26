import Foundation

struct TemplateFile {
    let path: String
    let template: String
}

struct ProjectConfiguration {
    let directories: [String]
    let files: [TemplateFile]

    static func vaporConfiguration() -> ProjectConfiguration {
        ProjectConfiguration(
            directories: [
                "Sources/App",
                "Sources/App/Domain/Entities",
                "Sources/App/Domain/ValueObjects",
                "Sources/App/Domain/Aggregates",
                "Sources/App/Domain/Events",
                "Sources/App/Domain/Repositories",
                "Sources/App/Domain/Services",
                "Sources/App/Application/UseCases",
                "Sources/App/Application/DTOs",
                "Sources/App/Infrastructure/Repositories",
                "Sources/App/Infrastructure/Migrations",
                "Sources/App/Infrastructure/Seeders",
                "Sources/App/Presentation/Controllers",
                "Sources/App/Presentation/Middleware",
                "Sources/App/Presentation/Routes",
                "Tests/AppTests",
            ],
            files: [
                TemplateFile(path: "Package.swift", template: "vapor/project/Package.swift.stencil"),
                TemplateFile(path: ".gitignore", template: "vapor/project/gitignore.stencil"),
                TemplateFile(path: ".numenrc.yml", template: "vapor/project/numenrc.yml.stencil"),
                TemplateFile(path: "Sources/App/entrypoint.swift", template: "vapor/project/entrypoint.swift.stencil"),
                TemplateFile(path: "Sources/App/configure.swift", template: "vapor/project/configure.swift.stencil"),
                TemplateFile(path: "Sources/App/Domain/DomainProtocols.swift", template: "vapor/project/DomainProtocols.swift.stencil"),
                TemplateFile(path: "Sources/App/Presentation/Routes/routes.swift", template: "vapor/project/routes.swift.stencil"),
                TemplateFile(path: "Tests/AppTests/AppTests.swift", template: "vapor/project/AppTests.swift.stencil"),
            ]
        )
    }
}
