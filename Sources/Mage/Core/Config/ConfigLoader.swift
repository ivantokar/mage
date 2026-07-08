import Foundation
import Yams

enum ConfigError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidYAML(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found at: \(path)"
        case .invalidYAML(let message):
            return "Invalid YAML format: \(message)"
        case .decodingError(let message):
            return "Failed to decode configuration: \(message)"
        }
    }
}

class ConfigLoader {
    private static let configFileName = ".magerc.yml"

    static func load() throws -> MageConfig {
        let currentPath = FileManager.default.currentDirectoryPath
        let configPath = "\(currentPath)/\(configFileName)"

        if FileManager.default.fileExists(atPath: configPath) {
            return try loadFromFile(at: configPath)
        } else {
            print("⚠️  No .magerc.yml found, using default configuration".yellow)
            return MageConfig.default
        }
    }

    static func loadFromFile(at path: String) throws -> MageConfig {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ConfigError.fileNotFound(path)
        }

        do {
            let yamlString = try String(contentsOfFile: path, encoding: .utf8)
            let decoder = YAMLDecoder()
            let config = try decoder.decode(MageConfig.self, from: yamlString)
            return config
        } catch let error as DecodingError {
            throw ConfigError.decodingError(error.localizedDescription)
        } catch {
            throw ConfigError.invalidYAML(error.localizedDescription)
        }
    }

    static func isInitialized() -> Bool {
        let currentPath = FileManager.default.currentDirectoryPath
        let configPath = "\(currentPath)/\(configFileName)"
        return FileManager.default.fileExists(atPath: configPath)
    }
}
