import Foundation

class PathResolver {
    private let config: MageConfig
    private let basePath: String

    init(config: MageConfig, basePath: String = FileManager.default.currentDirectoryPath) {
        self.config = config
        self.basePath = basePath
    }

    func resolvePath(componentType: DDDComponentType, customOutput: String? = nil) -> String {
        if let customOutput = customOutput {
            return "\(basePath)/\(customOutput)"
        }

        let layerPath: String
        switch componentType.layer {
        case "domain":
            layerPath = config.paths.domain
        case "application":
            layerPath = config.paths.application
        case "infrastructure":
            layerPath = config.paths.infrastructure
        case "persistence":
            layerPath = config.paths.persistence
        case "interface":
            layerPath = config.paths.interface
        case "tests":
            layerPath = config.paths.tests
        default:
            layerPath = config.paths.sources
        }

        let dir = componentType.directory
        return dir.isEmpty ? "\(basePath)/\(layerPath)" : "\(basePath)/\(layerPath)/\(dir)"
    }

    func ensureDirectoryExists(at path: String) throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func resolveFilePath(
        componentType: DDDComponentType,
        fileName: String,
        customOutput: String? = nil
    ) -> String {
        let directory = resolvePath(componentType: componentType, customOutput: customOutput)
        return "\(directory)/\(fileName)"
    }
}
