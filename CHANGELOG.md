# Changelog

Describes what the code does today. Plans live in GitHub issues (see CONTRIBUTING.md).

## Unreleased (1.0.0)

### Added

- vNext foundation (#31): `MageCore` (framework-independent) and the `mage` CLI root.
  - structured `Diagnostic`s with stable codes, and `MageError`;
  - `ProjectPath` and a narrow `FileSystem` boundary (`LocalFileSystem`, `InMemoryFileSystem`);
  - `GenerationPlan`, ownership model (user-owned, Mage-generated, managed integration),
    conflict detection and `GenerationResult`, with one shared path for dry run and apply
    and rollback when a write fails;
  - adapter ids and capability primitives, architecture profile primitives and the
    `CleanLayeredDDD` dependency rules;
  - a deterministic `Renderer` boundary;
  - global options `--verbose`, `--quiet`, `--no-color`.

### Removed

- The prototype command set (`mage new`, `mage entity`, `mage feature`, ...), its
  `.magerc.yml` schema and templates. They remain on `main` for reference.
