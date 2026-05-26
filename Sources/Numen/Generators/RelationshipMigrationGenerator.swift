import Foundation
import Prompt

class RelationshipMigrationGenerator {
    private let config: NumenConfig
    private let templateEngine: TemplateEngine
    private let pathResolver: PathResolver

    init(config: NumenConfig) throws {
        self.config = config
        self.templateEngine = try TemplateEngine()
        self.pathResolver = PathResolver(config: config)
    }

    func generate(
        context: GenerationContext,
        fromEntity: String,
        toEntity: String,
        relationshipType: RelationshipType
    ) throws {
        let migrationName: String
        let template: String

        switch relationshipType {
        case .manyToMany:
            migrationName = "Create\(fromEntity)\(toEntity)Pivot"
            template = "vapor/migrations/CreateJoinTableMigration.stencil"
        case .hasMany, .belongsTo:
            migrationName = "Add\(toEntity)To\(fromEntity)"
            template = "vapor/migrations/AddForeignKeyMigration.stencil"
        }

        let fileName = "\(migrationName).swift"
        let outputPath = pathResolver.resolvePath(
            componentType: .migration,
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
            "name": migrationName,
            "fromEntity": fromEntity,
            "toEntity": toEntity,
            "relationshipType": relationshipType.rawValue,
        ]

        let content = try templateEngine.render(template: template, context: templateContext)
        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)

        let relativePath = fullPath.replacingOccurrences(
            of: FileManager.default.currentDirectoryPath + "/", with: ""
        )
        print("✅ Created relationship migration: \(relativePath.green)")
    }
}

enum RelationshipType: String {
    case hasMany = "has-many"
    case belongsTo = "belongs-to"
    case manyToMany = "many-to-many"
}
