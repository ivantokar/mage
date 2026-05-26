import Foundation

enum GeneratorError: Error, LocalizedError {
    case fileAlreadyExists(String)
    case templateRenderingFailed(String)
    case fileWriteFailed(String)
    case missingRequiredField(String)

    var errorDescription: String? {
        switch self {
        case .fileAlreadyExists(let path):
            return "File already exists: \(path)"
        case .templateRenderingFailed(let message):
            return "Template rendering failed: \(message)"
        case .fileWriteFailed(let path):
            return "Failed to write file: \(path)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}

enum ProjectGeneratorError: Error, LocalizedError {
    case fileWriteFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileWriteFailed(let message):
            return message
        }
    }
}
