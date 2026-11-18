import Foundation
import Testing
@testable import MageCore

@Suite struct GenerationExecutorTests {
    private func executor(_ fs: any FileSystem) -> GenerationExecutor { GenerationExecutor(fileSystem: fs) }

    private func scaffoldPlan() -> GenerationPlan {
        var plan = GenerationPlan()
        plan.append(creatingParentsFor: .createFile(path("Sources/App/Domain/README.md"), contents: "domain\n", ownership: .userOwned))
        plan.append(creatingParentsFor: .createFile(path("Sources/App/Generated.swift"), contents: generated("let x = 1"), ownership: .mageGenerated))
        return plan
    }

    // MARK: Core flow

    @Test func applyCreatesWhatThePlanDescribes() throws {
        let fs = InMemoryFileSystem()
        let result = try executor(fs).run(scaffoldPlan(), mode: .apply)

        #expect(result.applied)
        #expect(result.created.map(\.description) == ["Sources", "Sources/App", "Sources/App/Domain", "Sources/App/Domain/README.md", "Sources/App/Generated.swift"])
        #expect(try fs.readString(at: path("Sources/App/Domain/README.md")) == "domain\n")
    }

    @Test func dryRunReportsTheSameChangesAndWritesNothing() throws {
        let fs = InMemoryFileSystem()
        let dry = try executor(fs).run(scaffoldPlan(), mode: .dryRun)
        #expect(try snapshot(fs).isEmpty)

        let real = try executor(fs).run(scaffoldPlan(), mode: .apply)
        #expect(!dry.applied)
        #expect(dry.entries == real.entries)
    }

    @Test func secondRunIsIdempotent() throws {
        let fs = InMemoryFileSystem()
        _ = try executor(fs).run(scaffoldPlan(), mode: .apply)
        let before = try snapshot(fs)

        let second = try executor(fs).run(scaffoldPlan(), mode: .apply)
        #expect(second.isNoOp)
        #expect(second.created.isEmpty && second.updated.isEmpty && second.removed.isEmpty)
        #expect(try snapshot(fs) == before)
    }

    @Test func parentDirectoriesAreNotDuplicated() {
        let plan = scaffoldPlan()
        let directories = plan.operations.compactMap { op -> String? in
            if case .createDirectory(let p) = op { return p.description }
            return nil
        }
        #expect(directories == ["Sources", "Sources/App", "Sources/App/Domain"])
    }

    // MARK: Conflicts

    @Test func differingExistingFileIsAConflict() throws {
        let fs = try InMemoryFileSystem(files: ["a.txt": "mine"])
        var plan = GenerationPlan()
        plan.append(.createFile(path("a.txt"), contents: "theirs", ownership: .userOwned))

        let error = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        #expect(error.diagnostics.map(\.code) == [.conflictContentsDiffer])
        #expect(try fs.readString(at: path("a.txt")) == "mine")
    }

    @Test func conflictAnywhereMeansNothingIsWritten() throws {
        let fs = try InMemoryFileSystem(files: ["b.txt": "mine"])
        var plan = GenerationPlan()
        plan.append(.createFile(path("a.txt"), contents: "new", ownership: .userOwned))
        plan.append(.createFile(path("b.txt"), contents: "other", ownership: .userOwned))

        #expect(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        #expect(try fs.kind(of: path("a.txt")) == nil)
    }

    @Test func dryRunFailsWithTheSameConflictsAsApply() throws {
        let fs = try InMemoryFileSystem(files: ["a.txt": "mine"])
        var plan = GenerationPlan()
        plan.append(.createFile(path("a.txt"), contents: "theirs", ownership: .userOwned))

        let dry = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .dryRun) }
        let real = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        #expect(dry == real)
    }

    @Test func missingParentIsAConflict() throws {
        var plan = GenerationPlan()
        plan.append(.createFile(path("x/y.txt"), contents: "c", ownership: .userOwned))
        let error = try #require(throws: MageError.self) { try executor(InMemoryFileSystem()).run(plan, mode: .apply) }
        #expect(error.diagnostics.map(\.code) == [.conflictMissingParent])
    }

    @Test func duplicatePathsAndWrongOwnershipAreInvalidPlans() throws {
        var plan = GenerationPlan()
        plan.append(.createFile(path("a"), contents: "1", ownership: .userOwned))
        plan.append(.createFile(path("a"), contents: "2", ownership: .userOwned))
        plan.append(.createFile(path("b"), contents: "x", ownership: .managedIntegration))
        plan.append(.createFile(path("c"), contents: "no header", ownership: .mageGenerated))
        plan.append(.replaceMageOwnedFile(path("d"), contents: "no header"))

        let error = try #require(throws: MageError.self) { try executor(InMemoryFileSystem()).run(plan, mode: .dryRun) }
        #expect(error.diagnostics.map(\.code) == Array(repeating: .invalidOperation, count: 4))
    }

    @Test func fileWhereDirectoryIsNeededIsAConflict() throws {
        let fs = try InMemoryFileSystem(files: ["Sources": "i am a file"])
        var plan = GenerationPlan()
        plan.append(.createDirectory(path("Sources")))
        let error = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        #expect(error.diagnostics.map(\.code) == [.conflictWrongKind])
    }

    // MARK: Ownership

    @Test func replacingAMageOwnedFileUpdatesIt() throws {
        let fs = try InMemoryFileSystem(files: ["g.swift": generated("old")])
        var plan = GenerationPlan()
        plan.append(.replaceMageOwnedFile(path("g.swift"), contents: generated("new")))
        let result = try executor(fs).run(plan, mode: .apply)
        #expect(result.updated == [path("g.swift")])
        #expect(try fs.readString(at: path("g.swift")) == generated("new"))
    }

    @Test func mageNeverReplacesOrRemovesAFileWithoutTheMarker() throws {
        let fs = try InMemoryFileSystem(files: ["g.swift": "// taken over by a developer\n"])
        for operation in [
            GenerationOperation.replaceMageOwnedFile(path("g.swift"), contents: generated("new")),
            .removeMageOwnedFile(path("g.swift")),
        ] {
            let error = try #require(throws: MageError.self) {
                try executor(fs).run(GenerationPlan(operations: [operation]), mode: .apply)
            }
            #expect(error.diagnostics.map(\.code) == [.conflictNotMageOwned])
        }
        #expect(try fs.readString(at: path("g.swift")) == "// taken over by a developer\n")
    }

    @Test func removingMageOwnedFiles() throws {
        let fs = try InMemoryFileSystem(files: ["g.swift": generated("x")])
        let plan = GenerationPlan(operations: [.removeMageOwnedFile(path("g.swift")), .removeMageOwnedFile(path("absent.swift"))])
        let result = try executor(fs).run(plan, mode: .apply)
        #expect(result.removed == [path("g.swift")])
        #expect(result.unchanged == [path("absent.swift")])
        #expect(try fs.kind(of: path("g.swift")) == nil)
    }

    @Test func markerMustBeOnTheFirstNonEmptyLine() {
        #expect(OwnershipMarker.isMageGenerated("\n\n\(generatedHeader)\ncode"))
        #expect(!OwnershipMarker.isMageGenerated("code\n\(generatedHeader)"))
        #expect(!OwnershipMarker.isMageGenerated(""))
    }

    // MARK: Managed integration

    @Test func hookUpdatesOnlyItsRegionAndIsIdempotent() throws {
        let original = "import Vapor\nfunc routes() {\n    // mage:begin routes\n    old()\n    // mage:end routes\n    userCode()\n}\n"
        let fs = try InMemoryFileSystem(files: ["routes.swift": original])
        let hook = try IntegrationHook(id: "routes", body: "register()")
        let plan = GenerationPlan(operations: [.addManagedIntegrationHook(path("routes.swift"), hook: hook)])

        let first = try executor(fs).run(plan, mode: .apply)
        #expect(first.updated == [path("routes.swift")])
        #expect(try fs.readString(at: path("routes.swift")) == "import Vapor\nfunc routes() {\n    // mage:begin routes\n    register()\n    // mage:end routes\n    userCode()\n}\n")

        #expect(try executor(fs).run(plan, mode: .apply).isNoOp)
    }

    @Test func hookWithoutRegionOrFileIsAConflictAndNeverGuesses() throws {
        let fs = try InMemoryFileSystem(files: ["routes.swift": "func routes() {}\n"])
        let hook = try IntegrationHook(id: "routes", body: "register()")

        let noRegion = try #require(throws: MageError.self) {
            try executor(fs).run(GenerationPlan(operations: [.addManagedIntegrationHook(path("routes.swift"), hook: hook)]), mode: .apply)
        }
        #expect(noRegion.diagnostics.map(\.code) == [.conflictIntegrationRegionMissing])
        #expect(try fs.readString(at: path("routes.swift")) == "func routes() {}\n")

        let noFile = try #require(throws: MageError.self) {
            try executor(fs).run(GenerationPlan(operations: [.addManagedIntegrationHook(path("none.swift"), hook: hook)]), mode: .apply)
        }
        #expect(noFile.diagnostics.map(\.code) == [.conflictIntegrationFileMissing])
    }

    @Test func invalidHookIdsAreRejected() {
        #expect(throws: MageError.self) { try IntegrationHook(id: "has space", body: "") }
        #expect(throws: MageError.self) { try IntegrationHook(id: "", body: "") }
    }

    // MARK: Rollback

    @Test func failedWriteRollsBackEverythingAlreadyWritten() throws {
        let base = try InMemoryFileSystem(files: ["keep.swift": generated("old")])
        let before = try snapshot(base)
        // Succeeds for the directory and first file, then fails.
        let fs = FailingFileSystem(base: base, failingAfter: 2)
        var plan = GenerationPlan()
        plan.append(.createDirectory(path("Sources")))
        plan.append(.createFile(path("Sources/a.txt"), contents: "a", ownership: .userOwned))
        plan.append(.replaceMageOwnedFile(path("keep.swift"), contents: generated("new")))
        plan.append(.createFile(path("Sources/b.txt"), contents: "b", ownership: .userOwned))

        let error = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        #expect(error.diagnostics.map(\.code) == [.generationFailed])
        #expect(try snapshot(base) == before)
    }

    @Test func incompleteRollbackIsReportedNotHidden() throws {
        let base = InMemoryFileSystem()
        // Fails the second write, then makes the cleanup of the first one fail as well.
        let fs = RollbackBlockingFileSystem(base: base)
        var plan = GenerationPlan()
        plan.append(.createFile(path("a.txt"), contents: "a", ownership: .userOwned))
        plan.append(.createFile(path("b.txt"), contents: "b", ownership: .userOwned))

        let error = try #require(throws: MageError.self) { try executor(fs).run(plan, mode: .apply) }
        let diagnostic = try #require(error.diagnostics.first)
        #expect(diagnostic.message.contains("Rollback was incomplete"))
        #expect(diagnostic.suggestion?.contains("a.txt") == true)
    }
}

/// Fails the second write and every removal, so the first write cannot be undone.
final class RollbackBlockingFileSystem: FileSystem, @unchecked Sendable {
    struct Injected: Error {}
    let base: any FileSystem
    private let lock = NSLock()
    private var writes = 0
    init(base: any FileSystem) { self.base = base }

    func kind(of path: ProjectPath) throws -> FileKind? { try base.kind(of: path) }
    func readFile(at path: ProjectPath) throws -> Data { try base.readFile(at: path) }
    func writeFile(_ data: Data, at path: ProjectPath) throws {
        lock.lock(); writes += 1; let n = writes; lock.unlock()
        if n == 2 { throw Injected() }
        try base.writeFile(data, at: path)
    }
    func createDirectory(at path: ProjectPath) throws { try base.createDirectory(at: path) }
    func removeFile(at path: ProjectPath) throws { throw Injected() }
    func removeDirectory(at path: ProjectPath) throws { throw Injected() }
    func contentsOfDirectory(at path: ProjectPath) throws -> [ProjectPath] { try base.contentsOfDirectory(at: path) }
}
