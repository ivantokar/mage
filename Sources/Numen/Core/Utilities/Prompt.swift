import Foundation
import Prompt

struct NumenPrompt {
    private static let service = PromptService()

    static func confirm(_ question: String, defaultValue: Bool = false) -> Bool {
        service.confirm(question, default: defaultValue)
    }

    static func ask(_ question: String, defaultValue: String? = nil) -> String? {
        let response = service.prompt(question, default: defaultValue)
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    static func choose(_ question: String, options: [String], defaultIndex: Int = 0) -> String? {
        guard !options.isEmpty else { return nil }
        let safeDefault = min(max(defaultIndex, 0), options.count - 1)
        let selectedIndex = service.select(question, options: options, default: safeDefault)
        return options[selectedIndex]
    }
}
