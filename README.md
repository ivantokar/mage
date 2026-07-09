<p align="center">
  <img src="mage-banner.png" alt="Mage - Domain-Driven Design for Vapor" width="700">
</p>

> Under construction: Mage is under active development. Expect breaking changes.

# Mage

Mage is a command-line tool for scaffolding [Vapor](https://vapor.codes) applications with a Clean Layered DDD architecture.

Full documentation: [mage.ivantokar.com](https://mage.ivantokar.com)

## Install From Source

```bash
git clone git@github.com:ivantokar/mage.git
cd mage
swift build -c release
cp .build/release/Mage /usr/local/bin/mage
```

Verify the install:

```bash
mage --help
```

## Contributor Setup

Build and test locally with Swift Package Manager:

```bash
swift build
swift test
```

Run the CLI from source:

```bash
swift run Mage --help
```

## Repository Layout

```text
Sources/Mage/
├── Commands/       CLI command definitions
├── Generators/     Code generation logic
├── Templates/      Stencil templates for generated Vapor code
├── Models/         Shared generation models
├── Core/           Config, file system, and template engine support
└── Utils/          Naming and field parsing helpers

Tests/MageTests/    Unit tests
```

## Notes For Contributors

- Keep generated Vapor output deterministic.
- Prefer focused tests around generator behavior and field parsing.
- Update the published docs source in the `ivantokar.com` repository, not here.
- Keep this repository focused on the Mage CLI and templates.

## License

MIT
