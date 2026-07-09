<p align="center">
  <img src="mage-banner-v2.png" alt="Mage - Domain-Driven Design for Vapor" width="500">
</p>

> 🚧 Under construction: Mage is under active development. Expect breaking changes.

# Mage

Mage is a command-line tool for scaffolding [Vapor](https://vapor.codes) applications with a Clean Layered DDD architecture. It generates the repetitive code around entities, value objects, use cases, repositories, controllers, routes, migrations, tests, and related project structure so you can focus on domain behavior.

📚 Full documentation: [mage.ivantokar.com](https://mage.ivantokar.com)

## ⚙️ Installation

Install with Homebrew:

```bash
brew tap ivantokar/homebrew-tap
brew install ivantokar/tap/mage
mage --help
```

`mage` also exists in Homebrew core as the Go Mage build tool. Use `ivantokar/tap/mage` to install this Swift Vapor scaffolding CLI.

If you already installed the Homebrew core formula by running `brew install mage`, remove it first:

```bash
brew uninstall mage
brew install ivantokar/tap/mage
```

Build from source with Swift Package Manager:

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

You can also run Mage directly from the checkout:

```bash
swift run Mage --help
```

## 🚀 Getting Started

Create a new Vapor project scaffolded with Mage's DDD layer structure:

```bash
mage new MyApp
cd MyApp
```

Configure project metadata during creation:

```bash
mage new MyApp --interactive
```

Common project options include:

```bash
mage new MyApp \
  --author "Your Name" \
  --company "Your Company" \
  --license MIT \
  --database postgres \
  --git
```

Inside a Mage-managed project, generate components:

```bash
mage entity User --fields "name:String,email:String,age:Int?"
mage repository UserRepository --entity User
mage migration CreateUser --entity User
```

Use `--dry-run` on supported generators to preview output before writing files:

```bash
mage feature Billing --dry-run
```

## 🧱 Generated Architecture

Mage-generated Vapor projects follow a layered DDD structure:

```text
Sources/App/
├── Domain/           Entities, value objects, aggregate roots, domain events
├── Application/      Use cases, DTOs, services
├── Infrastructure/   Fluent models, repository implementations, migrations
└── Interface/HTTP/   Controllers, routes, requests, responses, middleware
```

Project conventions are stored in `.magerc.yml`, generated with the project. It controls paths, naming conventions, database selection, and other generator defaults.

## 🛠️ Commands

| Command | Description |
|---|---|
| `mage new <name>` | Create a new Mage-managed Vapor project |
| `mage feature <name>` | Generate a complete DDD feature |
| `mage entity <name>` | Generate a domain entity |
| `mage value-object <name>` | Generate a value object |
| `mage aggregate-root <name>` | Generate an aggregate root |
| `mage domain-event <name>` | Generate a domain event |
| `mage service <name>` | Generate a domain service |
| `mage repository <name>` | Generate a repository protocol and Fluent implementation |
| `mage use-case <name>` | Generate an application use case |
| `mage dto <name>` | Generate a data transfer object |
| `mage controller <name>` | Generate a Vapor route controller |
| `mage route <name>` | Generate a route collection |
| `mage middleware <name>` | Generate a Vapor middleware |
| `mage migration <name>` | Generate a Fluent migration |
| `mage relationship <source> <target>` | Generate a relationship migration between two entities |
| `mage seeder <name>` | Generate a database seeder |
| `mage fluent-model <name>` | Generate a Fluent persistence model |
| `mage http-request <name>` | Generate HTTP request types |
| `mage http-response <name>` | Generate HTTP response types |
| `mage auth` | Generate JWT authentication scaffolding |
| `mage test <name>` | Generate a test file for a component |
| `mage docs` | Generate API documentation scaffolding inside a Mage-managed project |

Run command-specific help for details:

```bash
mage help entity
mage help feature
```

## 🧑‍💻 Development

Build and test locally:

```bash
swift build
swift test
```

Run the CLI from source:

```bash
swift run Mage --help
```

Repository layout:

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

## 🤝 Contributor Notes

- Keep generated Vapor output deterministic.
- Prefer focused tests around generator behavior, field parsing, and path/config handling.
- Keep this repository focused on the Mage CLI and templates.
- The published documentation source lives in the `ivantokar.com` repository, not here.

## 📄 License

MIT
