<p align="center">
  <img src="mage-banner-v2.png" alt="Mage - Domain-Driven Design for Vapor" width="500">
</p>

> 🚧 Under construction: this is the 1.0 rewrite branch. Mage has no usable commands yet.

# Mage

Mage is a project-aware development tool for initializing, generating, integrating, and validating Clean Layered DDD architecture inside **existing** server-side Swift projects. Generated applications remain normal framework applications and have no runtime dependency on Mage.

## Status

The 1.0 rewrite is tracked in [#30](https://github.com/ivantokar/mage/issues/30), one issue per phase. Work happens on `release/1.0`; `main` still holds the prototype (`mage new`, `mage entity`, ...), which the rewrite does not preserve.

What exists today (Phase 0, [#31](https://github.com/ivantokar/mage/issues/31)):

- `mage --help` and `mage --version`, with the global options `--verbose`, `--quiet` and `--no-color`;
- `MageCore`, a framework-independent library with structured diagnostics, a filesystem boundary, generation plans with ownership and conflict detection, adapter and architecture-profile primitives, and a renderer boundary.

`mage init`, `mage doctor` and every generator are **not implemented yet**.

## Development

```bash
swift build
swift test
swift run mage --help
```

Requires Swift 6.0 or later. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

```text
Sources/MageCore/   Framework-independent core (must not import Vapor, Fluent or any adapter)
Sources/MageCLI/    Argument parsing and console output
Sources/mage/       Executable entry point
Tests/              Unit tests
```

## License

MIT
