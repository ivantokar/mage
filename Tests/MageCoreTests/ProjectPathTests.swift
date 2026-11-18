import Foundation
import Testing
@testable import MageCore

@Suite struct ProjectPathTests {
    @Test func parsesRelativePaths() throws {
        let path = try ProjectPath("Sources/App/Domain")
        #expect(path.components == ["Sources", "App", "Domain"])
        #expect(path.description == "Sources/App/Domain")
        #expect(path.lastComponent == "Domain")
        #expect(path.parent?.description == "Sources/App")
    }

    @Test func emptyStringIsTheRoot() throws {
        let root = try ProjectPath("")
        #expect(root == .root)
        #expect(root.isRoot)
        #expect(root.parent == nil)
    }

    @Test(arguments: ["/etc/passwd", "../outside", "a/../b", "a/./b", "a//b", "a/", "back\\slash"])
    func rejectsUnsafePaths(_ string: String) {
        #expect(throws: MageError.self) { try ProjectPath(string) }
    }

    @Test func ancestorsExcludeRootAndSelf() throws {
        let path = try ProjectPath("a/b/c")
        #expect(path.ancestors.map(\.description) == ["a", "a/b"])
        #expect(try ProjectPath("a").ancestors.isEmpty)
    }

    @Test func appendingValidates() throws {
        #expect(try ProjectPath("a").appending("b/c").description == "a/b/c")
        #expect(throws: MageError.self) { try ProjectPath("a").appending("../x") }
    }

    @Test func prefix() throws {
        #expect(try ProjectPath("a/b/c").hasPrefix(ProjectPath("a/b")))
        #expect(try !ProjectPath("a/bc").hasPrefix(ProjectPath("a/b")))
    }

    @Test func codableRoundTripsAsString() throws {
        let data = try JSONEncoder().encode([try ProjectPath("a/b")])
        #expect(String(decoding: data, as: UTF8.self) == "[\"a\\/b\"]")
        #expect(try JSONDecoder().decode([ProjectPath].self, from: data) == [try ProjectPath("a/b")])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([ProjectPath].self, from: Data("[\"../x\"]".utf8)) }
    }
}
