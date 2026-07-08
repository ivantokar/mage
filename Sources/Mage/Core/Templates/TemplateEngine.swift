import Foundation
import Stencil
import PathKit
import SwiftStencilKit

enum TemplateError: Error, LocalizedError {
    case templateNotFound(String)
    case renderingFailed(String)

    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template not found: \(name)"
        case .renderingFailed(let message):
            return "Template rendering failed: \(message)"
        }
    }
}

class TemplateEngine {
    private let environment: Environment

    init(templatesPath: String? = nil) throws {
        let basePath = templatesPath ?? Self.findTemplatesDirectory()
        let loader = FileSystemLoader(paths: [Path(basePath)])
        self.environment = Environment(loader: loader)
        SwiftStencilFilters.register(on: self.environment)
    }

    private static func findTemplatesDirectory() -> String {
        let currentPath = FileManager.default.currentDirectoryPath

        let localTemplates = "\(currentPath)/Templates"
        if FileManager.default.fileExists(atPath: localTemplates) {
            return localTemplates
        }

        let devTemplates = "\(currentPath)/Sources/Mage/Templates"
        if FileManager.default.fileExists(atPath: devTemplates) {
            return devTemplates
        }

        let moduleTemplates = Bundle.module.bundleURL
            .appendingPathComponent("Templates")
            .path
        if FileManager.default.fileExists(atPath: moduleTemplates) {
            return moduleTemplates
        }

        if let resourcePath = Bundle.main.resourcePath {
            let bundleTemplates = "\(resourcePath)/Templates"
            if FileManager.default.fileExists(atPath: bundleTemplates) {
                return bundleTemplates
            }
        }

        if let executablePath = Bundle.main.executablePath {
            let execURL = URL(fileURLWithPath: executablePath)
            let bundlePath = execURL.deletingLastPathComponent()
                .appendingPathComponent("mage_Mage.bundle/Templates").path
            if FileManager.default.fileExists(atPath: bundlePath) {
                return bundlePath
            }
        }

        return "\(currentPath)/Templates"
    }

    func render(template: String, context: [String: Any]) throws -> String {
        do {
            return try environment.renderTemplate(name: template, context: context)
        } catch {
            throw TemplateError.renderingFailed(error.localizedDescription)
        }
    }

    func render(
        template: String,
        context: [String: Any],
        header: String
    ) throws -> String {
        var fullContext = context
        fullContext["header"] = header
        return try render(template: template, context: fullContext)
    }
}
