import Foundation
import Prompt

class ServiceGenerator {
    private let config: MageConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: MageConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext) throws {
        let fileName = "\(context.name).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .service,
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
        ]

        let content = try templateEngine.render(
            template: "vapor/components/Service.stencil",
            context: templateContext
        )

        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created service: \(relativePath.green)")
    }
}
