import Foundation

enum EntityFieldIntrospector {
    static func loadFields(
        entityName: String,
        config: NumenConfig,
        baseDir: String = FileManager.default.currentDirectoryPath
    ) -> [Field]? {
        let entityPath = "\(baseDir)/\(config.paths.domain)/Entities/\(entityName).swift"
        guard FileManager.default.fileExists(atPath: entityPath),
              let content = try? String(contentsOfFile: entityPath, encoding: .utf8) else {
            return nil
        }
        return parseFields(from: content)
    }

    private static func parseFields(from content: String) -> [Field] {
        let fieldPattern = #"@Field\(key:\s*"([^"]+)"\)\s*var\s+(\w+):\s*(\w+)(\?)?  "#
        guard let regex = try? NSRegularExpression(pattern: fieldPattern) else { return [] }

        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        return matches.compactMap { match -> Field? in
            guard match.numberOfRanges == 5,
                  let nameRange = Range(match.range(at: 2), in: content),
                  let typeRange = Range(match.range(at: 3), in: content) else { return nil }

            let name = String(content[nameRange])
            let type = String(content[typeRange])
            let optional = match.range(at: 4).location != NSNotFound

            return Field(name: name, type: type, optional: optional)
        }
    }
}
