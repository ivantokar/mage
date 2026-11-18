/// One filesystem mutation Mage intends to make.
///
/// The set is deliberately narrow. There is no "edit an arbitrary file" operation:
/// every change is either a whole Mage-owned file or a Mage-managed region.
public enum GenerationOperation: Sendable, Equatable {
    /// Creates a directory. Unchanged when it already exists.
    case createDirectory(ProjectPath)

    /// Creates a file. Unchanged when it already exists with identical contents,
    /// a conflict when it exists with different contents. `ownership` must be
    /// ``FileOwnership/userOwned`` or ``FileOwnership/mageGenerated``.
    case createFile(ProjectPath, contents: String, ownership: FileOwnership)

    /// Creates or replaces a file that Mage owns. Conflicts when the existing file
    /// does not carry the ``OwnershipMarker``.
    case replaceMageOwnedFile(ProjectPath, contents: String)

    /// Updates a Mage-managed region inside an existing file.
    case addManagedIntegrationHook(ProjectPath, hook: IntegrationHook)

    /// Removes a Mage-owned file. Conflicts when the file does not carry the
    /// ``OwnershipMarker``; unchanged when it does not exist.
    case removeMageOwnedFile(ProjectPath)

    public var path: ProjectPath {
        switch self {
        case .createDirectory(let p), .createFile(let p, _, _), .replaceMageOwnedFile(let p, _),
            .addManagedIntegrationHook(let p, _), .removeMageOwnedFile(let p):
            p
        }
    }
}

/// A complete, ordered description of the changes a command wants to make.
///
/// Commands build a plan; they never touch the filesystem themselves. The same plan
/// is evaluated for `--dry-run` and applied for a real run (see ``GenerationExecutor``),
/// so what a dry run reports is what a real run does.
public struct GenerationPlan: Sendable, Equatable {
    public private(set) var operations: [GenerationOperation]

    public init(operations: [GenerationOperation] = []) {
        self.operations = operations
    }

    public var isEmpty: Bool { operations.isEmpty }

    public mutating func append(_ operation: GenerationOperation) {
        operations.append(operation)
    }

    /// Adds directory operations for every ancestor of `path` that the plan does not
    /// already create, then the operation itself.
    public mutating func append(creatingParentsFor operation: GenerationOperation) {
        let existing = Set(operations.compactMap { op -> ProjectPath? in
            if case .createDirectory(let p) = op { return p }
            return nil
        })
        for ancestor in operation.path.ancestors where !existing.contains(ancestor) {
            operations.append(.createDirectory(ancestor))
        }
        operations.append(operation)
    }
}
