import Foundation
import Prompt

class DocsGenerator {
    private let config: MageConfig
    private let templateEngine: TemplateEngine

    init(config: MageConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
    }

    func generate(context: GenerationContext) throws {
        let basePath = FileManager.default.currentDirectoryPath
        let docsPath = "\(basePath)/docs"

        if context.dryRun {
            print("Would create: \(docsPath)/api.md".yellow)
            return
        }

        try FileManager.default.createDirectory(
            atPath: docsPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let files: [(name: String, template: String)] = [
            ("api.md", "vapor/docs/api.md.stencil"),
            ("architecture.md", "vapor/docs/architecture.md.stencil"),
        ]

        let templateContext: [String: Any] = [
            "projectName": context.name,
        ]

        for (name, template) in files {
            let fullPath = "\(docsPath)/\(name)"
            if FileManager.default.fileExists(atPath: fullPath) {
                print("⚠️  Skipping existing: docs/\(name)".yellow)
                continue
            }
            let content = try templateEngine.render(template: template, context: templateContext)
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
            print("✅ Created: docs/\(name)".green)
        }
    }
}
