import Foundation

/// Why an operation cannot be carried out safely.
public enum ConflictReason: Sendable, Equatable {
    /// A file exists at the path with contents that differ from the plan.
    case fileExistsWithDifferentContents
    /// A file exists but does not carry the Mage ownership marker.
    case notMageOwned
    /// The path exists but is a file where a directory is needed, or the reverse.
    case wrongKind(existing: FileKind)
    /// The parent directory neither exists nor is created earlier in the plan.
    case missingParentDirectory
    /// A managed integration needs an existing file.
    case integrationFileMissing
    /// The file has no region for the hook, so Mage will not guess where to insert it.
    case integrationRegionMissing(hook: String)
    /// The plan itself is malformed (duplicate path, wrong ownership, missing marker).
    case invalidOperation(String)
}

public struct Conflict: Sendable, Equatable {
    public var path: ProjectPath
    public var reason: ConflictReason

    public var diagnostic: Diagnostic {
        let location = DiagnosticLocation(path: path)
        switch reason {
        case .fileExistsWithDifferentContents:
            return Diagnostic(
                code: .conflictContentsDiffer, severity: .error,
                message: "'\(path)' already exists with different contents.",
                location: location,
                suggestion: "Review the file and merge the change by hand, or move it out of the way.")
        case .notMageOwned:
            return Diagnostic(
                code: .conflictNotMageOwned, severity: .error,
                message: "'\(path)' is not a Mage-generated file, so Mage will not change it.",
                location: location,
                suggestion: "Mage only replaces or removes files that start with its \"\(OwnershipMarker.text)\" header.")
        case .wrongKind(let existing):
            return Diagnostic(
                code: .conflictWrongKind, severity: .error,
                message: "'\(path)' exists but is a \(existing == .file ? "file" : "directory").",
                location: location)
        case .missingParentDirectory:
            return Diagnostic(
                code: .conflictMissingParent, severity: .error,
                message: "The parent directory of '\(path)' does not exist.",
                location: location)
        case .integrationFileMissing:
            return Diagnostic(
                code: .conflictIntegrationFileMissing, severity: .error,
                message: "'\(path)' does not exist, so Mage cannot update its managed region.",
                location: location)
        case .integrationRegionMissing(let hook):
            return Diagnostic(
                code: .conflictIntegrationRegionMissing, severity: .error,
                message: "'\(path)' has no 'mage:begin \(hook)' / 'mage:end \(hook)' region.",
                location: location,
                suggestion: "Add the region to the file by hand; Mage never guesses where to insert code.")
        case .invalidOperation(let message):
            return Diagnostic(
                code: .invalidOperation, severity: .error,
                message: "Invalid generation plan for '\(path)': \(message)",
                location: location)
        }
    }
}

extension DiagnosticCode {
    public static let conflictContentsDiffer = DiagnosticCode("generation.conflict.contents-differ")
    public static let conflictNotMageOwned = DiagnosticCode("generation.conflict.not-mage-owned")
    public static let conflictWrongKind = DiagnosticCode("generation.conflict.wrong-kind")
    public static let conflictMissingParent = DiagnosticCode("generation.conflict.missing-parent")
    public static let conflictIntegrationFileMissing = DiagnosticCode("generation.conflict.integration-file-missing")
    public static let conflictIntegrationRegionMissing = DiagnosticCode("generation.conflict.integration-region-missing")
    public static let invalidOperation = DiagnosticCode("generation.plan.invalid-operation")
    public static let generationFailed = DiagnosticCode("generation.apply.failed")
}

/// What the executor will do for each operation, decided before anything is written.
struct PlanEvaluation {
    enum Action: Equatable {
        case createDirectory
        case writeFile(String, previous: String?)
        case removeFile(previous: String)
        case none
    }

    struct Item {
        var operation: GenerationOperation
        var action: Action
        var change: GenerationResult.Change
    }

    var items: [Item] = []
    var conflicts: [Conflict] = []
}

/// Evaluates a plan against a filesystem without changing it.
struct PlanEvaluator {
    let fileSystem: any FileSystem

    func evaluate(_ plan: GenerationPlan) throws -> PlanEvaluation {
        var result = PlanEvaluation()
        var seen = Set<ProjectPath>()
        // Directories the plan creates, so a file may be created inside one.
        var plannedDirectories = Set<ProjectPath>()

        for operation in plan.operations {
            let path = operation.path
            func conflict(_ reason: ConflictReason) {
                result.conflicts.append(Conflict(path: path, reason: reason))
            }

            if !seen.insert(path).inserted {
                conflict(.invalidOperation("more than one operation targets this path"))
                continue
            }

            func parentIsAvailable() throws -> Bool {
                guard let parent = path.parent else { return false }
                if plannedDirectories.contains(parent) { return true }
                return try fileSystem.kind(of: parent) == .directory
            }

            switch operation {
            case .createDirectory:
                switch try fileSystem.kind(of: path) {
                case .directory:
                    result.items.append(.init(operation: operation, action: .none, change: .unchanged))
                case .file:
                    conflict(.wrongKind(existing: .file))
                case nil:
                    guard try parentIsAvailable() else { conflict(.missingParentDirectory); continue }
                    plannedDirectories.insert(path)
                    result.items.append(.init(operation: operation, action: .createDirectory, change: .created))
                }

            case .createFile(_, let contents, let ownership):
                if ownership == .managedIntegration {
                    conflict(.invalidOperation("createFile cannot create a managed-integration file"))
                    continue
                }
                if ownership == .mageGenerated, !OwnershipMarker.isMageGenerated(contents) {
                    conflict(.invalidOperation("Mage-generated contents must start with the ownership header"))
                    continue
                }
                switch try fileSystem.kind(of: path) {
                case .directory:
                    conflict(.wrongKind(existing: .directory))
                case .file:
                    let existing = try fileSystem.readString(at: path)
                    if existing == contents {
                        result.items.append(.init(operation: operation, action: .none, change: .unchanged))
                    } else {
                        conflict(.fileExistsWithDifferentContents)
                    }
                case nil:
                    guard try parentIsAvailable() else { conflict(.missingParentDirectory); continue }
                    result.items.append(.init(operation: operation, action: .writeFile(contents, previous: nil), change: .created))
                }

            case .replaceMageOwnedFile(_, let contents):
                guard OwnershipMarker.isMageGenerated(contents) else {
                    conflict(.invalidOperation("Mage-generated contents must start with the ownership header"))
                    continue
                }
                switch try fileSystem.kind(of: path) {
                case .directory:
                    conflict(.wrongKind(existing: .directory))
                case .file:
                    let existing = try fileSystem.readString(at: path)
                    if !OwnershipMarker.isMageGenerated(existing) {
                        conflict(.notMageOwned)
                    } else if existing == contents {
                        result.items.append(.init(operation: operation, action: .none, change: .unchanged))
                    } else {
                        result.items.append(.init(operation: operation, action: .writeFile(contents, previous: existing), change: .updated))
                    }
                case nil:
                    guard try parentIsAvailable() else { conflict(.missingParentDirectory); continue }
                    result.items.append(.init(operation: operation, action: .writeFile(contents, previous: nil), change: .created))
                }

            case .addManagedIntegrationHook(_, let hook):
                switch try fileSystem.kind(of: path) {
                case nil:
                    conflict(.integrationFileMissing)
                case .directory:
                    conflict(.wrongKind(existing: .directory))
                case .file:
                    let existing = try fileSystem.readString(at: path)
                    guard let updated = hook.apply(to: existing) else {
                        conflict(.integrationRegionMissing(hook: hook.id))
                        continue
                    }
                    if updated == existing {
                        result.items.append(.init(operation: operation, action: .none, change: .unchanged))
                    } else {
                        result.items.append(.init(operation: operation, action: .writeFile(updated, previous: existing), change: .updated))
                    }
                }

            case .removeMageOwnedFile:
                switch try fileSystem.kind(of: path) {
                case nil:
                    result.items.append(.init(operation: operation, action: .none, change: .unchanged))
                case .directory:
                    conflict(.wrongKind(existing: .directory))
                case .file:
                    let existing = try fileSystem.readString(at: path)
                    if OwnershipMarker.isMageGenerated(existing) {
                        result.items.append(.init(operation: operation, action: .removeFile(previous: existing), change: .removed))
                    } else {
                        conflict(.notMageOwned)
                    }
                }
            }
        }
        return result
    }
}
