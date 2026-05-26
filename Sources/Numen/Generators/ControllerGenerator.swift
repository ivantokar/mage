import Foundation
import Prompt

class ControllerGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext, entityName: String? = nil) throws {
        let fileName = "\(context.name).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .controller,
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

        let resolvedEntityName = entityName ?? context.entity ?? context.name
        let templateContext: [String: Any] = [
            "name": context.name,
            "entityName": resolvedEntityName,
            "fields": context.fields.map { $0.toDictionary() },
            "hasFields": !context.fields.isEmpty,
        ]

        let content = try templateEngine.render(
            template: "vapor/components/Controller.stencil",
            context: templateContext
        )

        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created controller: \(relativePath.green)")
    }
}
