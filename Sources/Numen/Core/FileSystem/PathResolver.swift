import Foundation

class PathResolver {
    private let config: NumenConfig
    private let basePath: String

    init(config: NumenConfig, basePath: String = FileManager.default.currentDirectoryPath) {
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
        case "presentation":
            layerPath = config.paths.presentation
        case "infrastructure":
            layerPath = config.paths.infrastructure
        case "tests":
            layerPath = config.paths.tests
        default:
            layerPath = config.paths.sources
        }

        return "\(basePath)/\(layerPath)/\(componentType.directory)"
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
