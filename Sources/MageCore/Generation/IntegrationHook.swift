/// A Mage-managed region inside an otherwise user-owned file.
///
/// ```swift
/// // mage:begin routes
/// try registerGeneratedRoutes(app)
/// // mage:end routes
/// ```
///
/// Mage changes only the lines between the markers, and only when both markers are
/// present. Inserting a region into a file that has none is a separate, explicit
/// operation owned by the framework adapters (roadmap phase 10).
public struct IntegrationHook: Sendable, Hashable {
    public var id: String
    public var body: String
    public var commentPrefix: String

    public init(id: String, body: String, commentPrefix: String = "//") throws {
        guard !id.isEmpty, id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == ".") }) else {
            throw MageError(
                code: .invalidHook,
                message: "Invalid integration hook id '\(id)': use letters, digits, '-' and '.'.")
        }
        self.id = id
        self.body = body
        self.commentPrefix = commentPrefix
    }

    var beginMarker: String { "\(commentPrefix) mage:begin \(id)" }
    var endMarker: String { "\(commentPrefix) mage:end \(id)" }

    /// The full managed region, including both markers.
    var region: String { "\(beginMarker)\n\(body)\n\(endMarker)" }

    /// Applies the hook to `contents`. Returns `nil` when the file has no region for this hook.
    func apply(to contents: String) -> String? {
        var lines = contents.components(separatedBy: "\n")
        guard
            let begin = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == beginMarker }),
            let end = lines[(begin + 1)...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == endMarker })
        else { return nil }
        let indent = String(lines[begin].prefix { $0 == " " || $0 == "\t" })
        let newBody = body.isEmpty ? [] : body.components(separatedBy: "\n").map { $0.isEmpty ? $0 : indent + $0 }
        lines.replaceSubrange((begin + 1)..<end, with: newBody)
        return lines.joined(separator: "\n")
    }
}

extension DiagnosticCode {
    public static let invalidHook = DiagnosticCode("generation.hook.invalid")
}

import Foundation
