import Foundation
import Testing

/// Phase 0 exit criterion: Core does not import Vapor, Fluent or any concrete adapter.
@Suite struct CoreBoundaryTests {
    static let forbidden: Set<String> = [
        "Vapor", "Fluent", "FluentKit", "FluentPostgresDriver", "FluentSQLiteDriver", "FluentMySQLDriver",
        "Hummingbird", "NIO", "ArgumentParser", "Yams", "Stencil", "SwiftStencilKit", "Prompt",
    ]

    @Test func coreImportsNoConcreteAdaptersOrPresentationLibraries() throws {
        let core = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/MageCore")
        let files = try #require(FileManager.default.enumerator(at: core, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)

        var violations: [String] = []
        for file in files {
            for line in try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n") {
                let words = line.split(separator: " ").map(String.init)
                guard words.first == "import" || (words.count > 1 && words[0] == "@testable" && words[1] == "import") else { continue }
                let module = words.last!.split(separator: ".").first.map(String.init) ?? ""
                if Self.forbidden.contains(module) { violations.append("\(file.lastPathComponent): \(line)") }
            }
        }
        #expect(violations.isEmpty, "MageCore must stay framework-independent: \(violations)")
    }
}
