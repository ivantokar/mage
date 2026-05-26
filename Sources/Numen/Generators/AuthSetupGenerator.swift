import Foundation
import Prompt

class AuthSetupGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext) throws {
        let files: [(path: String, template: String)] = [
            (
                "\(config.paths.domain)/Entities/User.swift",
                "vapor/auth/UserModel.stencil"
            ),
            (
                "\(config.paths.presentation)/Controllers/AuthController.swift",
                "vapor/auth/AuthController.stencil"
            ),
            (
                "\(config.paths.presentation)/Middleware/AuthMiddleware.swift",
                "vapor/auth/AuthMiddleware.stencil"
            ),
            (
                "\(config.paths.infrastructure)/Migrations/CreateUser.swift",
                "vapor/auth/CreateUserMigration.stencil"
            ),
            (
                "\(config.paths.infrastructure)/Migrations/CreateToken.swift",
                "vapor/auth/CreateTokenMigration.stencil"
            ),
        ]

        let basePath = FileManager.default.currentDirectoryPath
        var generated: [String] = []

        for (relativePath, template) in files {
            let fullPath = "\(basePath)/\(relativePath)"

            if context.dryRun {
                print("Would create: \(fullPath)".yellow)
                continue
            }

            if pathResolver.fileExists(at: fullPath) {
                print("⚠️  Skipping existing: \(relativePath)".yellow)
                continue
            }

            let dir = (fullPath as NSString).deletingLastPathComponent
            try pathResolver.ensureDirectoryExists(at: dir)

            let templateContext: [String: Any] = [:]
            let content = try templateEngine.render(template: template, context: templateContext)
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)

            let rel = fullPath.replacingOccurrences(of: "\(basePath)/", with: "")
            print("✅ Created: \(rel.green)")
            generated.append(rel)
        }

        if !context.dryRun && !generated.isEmpty {
            print()
            print("Auth scaffolding generated. Remember to:".bold)
            print("  1. Register migrations in configure.swift")
            print("  2. Register auth routes in routes.swift")
            print("  3. Configure JWT secret in environment")
        }
    }
}
