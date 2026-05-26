import Foundation
import Prompt

class UseCaseGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext) throws {
        let fileName = "\(context.name).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .useCase,
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
            "entityName": context.entity as Any,
            "fields": context.fields.map { $0.toDictionary() },
            "hasFields": !context.fields.isEmpty,
        ]

        let content = try templateEngine.render(
            template: "vapor/components/UseCase.stencil",
            context: templateContext
        )

        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created use case: \(relativePath.green)")
    }
}

class CRUDUseCasesGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(context: GenerationContext, entityName: String, repositoryName: String, dtoName: String) throws {
        let operations: [(name: String, template: String)] = [
            ("Create\(entityName)UseCase", "vapor/components/CreateUseCase.stencil"),
            ("Get\(entityName)ByIdUseCase", "vapor/components/GetByIdUseCase.stencil"),
            ("GetAll\(entityName)sUseCase", "vapor/components/GetAllUseCase.stencil"),
            ("Update\(entityName)UseCase", "vapor/components/UpdateUseCase.stencil"),
            ("Delete\(entityName)UseCase", "vapor/components/DeleteUseCase.stencil"),
        ]

        let outputPath = pathResolver.resolvePath(
            componentType: .useCase,
            customOutput: context.outputPath
        )

        if context.dryRun {
            for op in operations {
                print("Would create: \(outputPath)/\(op.name).swift".yellow)
            }
            return
        }

        try pathResolver.ensureDirectoryExists(at: outputPath)

        for (name, template) in operations {
            let fileName = "\(name).swift"
            let fullPath = "\(outputPath)/\(fileName)"

            if pathResolver.fileExists(at: fullPath) {
                print("⚠️  Skipping existing: \(fileName)".yellow)
                continue
            }

            let templateContext: [String: Any] = [
                "name": name,
                "entityName": entityName,
                "repositoryName": repositoryName,
                "dtoName": dtoName,
                "fields": context.fields.map { $0.toDictionary() },
                "hasFields": !context.fields.isEmpty,
            ]

            let content = try templateEngine.render(
                template: template,
                context: templateContext
            )

            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
            let relativePath = fullPath.replacingOccurrences(
                of: FileManager.default.currentDirectoryPath + "/", with: ""
            )
            print("✅ Created use case: \(relativePath.green)")
        }
    }
}
