import Foundation
import Prompt

class RepositoryGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext) throws {
        guard let entityName = context.entity else {
            throw GeneratorError.missingRequiredField("entity name is required for repository generation")
        }

        try generateProtocol(context: context, entityName: entityName)
        try generateImplementation(context: context, entityName: entityName)
    }

    private func generateProtocol(context: GenerationContext, entityName: String) throws {
        let fileName = "\(context.name).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .repository,
            customOutput: context.outputPath
        )
        let fullPath = "\(outputPath)/\(fileName)"

        if context.dryRun {
            print("Would create: \(fullPath)".yellow)
            return
        }

        if pathResolver.fileExists(at: fullPath) {
            throw GeneratorError.fileAlreadyExists(fullPath)
        }

        try pathResolver.ensureDirectoryExists(at: outputPath)

        let templateContext: [String: Any] = [
            "name": context.name,
            "entityName": entityName,
        ]

        let content = try templateEngine.render(
            template: "vapor/components/Repository.stencil",
            context: templateContext
        )

        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created repository protocol: \(relativePath.green)")
    }

    private func generateImplementation(context: GenerationContext, entityName: String) throws {
        let implName = "Fluent\(context.name)"
        let fileName = "\(implName).swift"

        let implOutputPath: String
        if let customOutput = context.outputPath {
            implOutputPath = pathResolver.resolvePath(componentType: .repository, customOutput: customOutput)
                .replacingOccurrences(of: "/Domain/Repositories", with: "/Infrastructure/Persistence/Fluent/Repositories")
        } else {
            implOutputPath = "\(FileManager.default.currentDirectoryPath)/\(config.paths.persistence)/Repositories"
        }

        let fullPath = "\(implOutputPath)/\(fileName)"

        if context.dryRun {
            print("Would create: \(fullPath)".yellow)
            return
        }

        if pathResolver.fileExists(at: fullPath) {
            throw GeneratorError.fileAlreadyExists(fullPath)
        }

        try pathResolver.ensureDirectoryExists(at: implOutputPath)

        let templateContext: [String: Any] = [
            "implName": implName,
            "protocolName": context.name,
            "entityName": entityName,
            "fields": context.fields.map { $0.toDictionary() },
        ]

        let content = try templateEngine.render(
            template: "vapor/components/RepositoryImpl.stencil",
            context: templateContext
        )

        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created repository implementation: \(relativePath.green)")
    }
}
