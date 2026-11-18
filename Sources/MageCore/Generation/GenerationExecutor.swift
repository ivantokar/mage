import Foundation

/// Evaluates and applies a ``GenerationPlan``.
///
/// Dry run and apply share one path: both evaluate the plan against the filesystem and
/// fail with the same conflicts. Only ``Mode/apply`` then writes. If a write fails
/// part-way, everything already written is rolled back and the run fails.
public struct GenerationExecutor: Sendable {
    public enum Mode: Sendable { case dryRun, apply }

    private let fileSystem: any FileSystem

    public init(fileSystem: any FileSystem) {
        self.fileSystem = fileSystem
    }

    public func run(_ plan: GenerationPlan, mode: Mode) throws -> GenerationResult {
        let evaluation = try PlanEvaluator(fileSystem: fileSystem).evaluate(plan)
        if !evaluation.conflicts.isEmpty {
            throw MageError(diagnostics: evaluation.conflicts.map(\.diagnostic))
        }

        let entries = evaluation.items.map { item in
            var isDirectory = false
            if case .createDirectory = item.operation { isDirectory = true }
            return GenerationResult.Entry(path: item.operation.path, isDirectory: isDirectory, change: item.change)
        }

        if mode == .apply { try apply(evaluation) }
        return GenerationResult(applied: mode == .apply, entries: entries)
    }

    private func apply(_ evaluation: PlanEvaluation) throws {
        // Each step records how to undo itself, so a failure part-way leaves the project as it was.
        var undo: [(path: ProjectPath, action: () throws -> Void)] = []
        do {
            for item in evaluation.items {
                let path = item.operation.path
                switch item.action {
                case .none:
                    break
                case .createDirectory:
                    try fileSystem.createDirectory(at: path)
                    undo.append((path, { [fileSystem] in try fileSystem.removeDirectory(at: path) }))
                case .writeFile(let contents, let previous):
                    try fileSystem.writeString(contents, at: path)
                    undo.append((path, { [fileSystem] in
                        if let previous { try fileSystem.writeString(previous, at: path) } else { try fileSystem.removeFile(at: path) }
                    }))
                case .removeFile(let previous):
                    try fileSystem.removeFile(at: path)
                    undo.append((path, { [fileSystem] in try fileSystem.writeString(previous, at: path) }))
                }
            }
        } catch {
            var notRestored: [ProjectPath] = []
            for step in undo.reversed() {
                do { try step.action() } catch { notRestored.append(step.path) }
            }
            var message = "Generation failed: \(error)"
            var suggestion: String?
            if notRestored.isEmpty {
                message += " All changes were rolled back."
            } else {
                message += " Rollback was incomplete."
                suggestion = "Check these paths by hand: \(notRestored.map(\.description).joined(separator: ", "))."
            }
            throw MageError(code: .generationFailed, message: message, suggestion: suggestion)
        }
    }
}
