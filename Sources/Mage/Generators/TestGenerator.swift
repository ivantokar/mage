import Foundation
import Prompt

class TestGenerator {
    private let config: MageConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: MageConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext, targetType: TestTargetType) throws {
        let template: String
        let suffix: String

        switch targetType {
        case .entity:
            template = "vapor/tests/EntityTest.stencil"
            suffix = "Tests"
        case .repository:
            template = "vapor/tests/RepositoryTest.stencil"
            suffix = "Tests"
        case .useCase:
            template = "vapor/tests/UseCaseTest.stencil"
            suffix = "Tests"
        case .controller:
            template = "vapor/tests/ControllerTest.stencil"
            suffix = "Tests"
        case .feature:
            template = "vapor/tests/FeatureTest.stencil"
            suffix = "FeatureTests"
        }

        let baseName = context.name.hasSuffix("Tests") ? context.name : "\(context.name)\(suffix)"
        let fileName = "\(baseName).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .test,
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
            "name": baseName,
            "targetName": context.name,
            "entityName": context.entity ?? context.name,
        ]

        let content = try templateEngine.render(template: template, context: templateContext)
        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)

        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created test: \(relativePath.green)")
    }
}

enum TestTargetType: String {
    case entity
    case repository
    case useCase = "use-case"
    case controller
    case feature
}
