import Foundation
import Prompt

class EntityGenerator {
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
            componentType: .entity,
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
            "fields": context.fields.map { $0.toDictionary() },
            "aggregate": context.aggregate as Any,
            "hasFields": !context.fields.isEmpty,
        ]

        let content = try templateEngine.render(
            template: "vapor/components/Entity.stencil",
            context: templateContext
        )

        try writeFile(content: content, path: fullPath)
        printSuccess(path: fullPath, label: "entity")

        if !context.fields.isEmpty {
            print("   Fields: \(context.fields.map { $0.name }.joined(separator: ", "))".dim)
        }
    }

    private func writeFile(content: String, path: String) throws {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw GeneratorError.fileWriteFailed(path)
        }
    }

    private func printSuccess(path: String, label: String) {
        let relativePath = path.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/",
            with: ""
        )
        print("✅ Created \(label): \(relativePath.green)")
    }
}
