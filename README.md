<p align="center">
  <img src="mage-banner.png" alt="Mage — Domain-Driven Design for Vapor" width="700">
</p>

> 🚧 **Under construction** — Mage is under active development. Expect breaking changes.

# Mage

Mage is a command-line tool for scaffolding [Vapor](https://vapor.codes) applications using a Clean Layered DDD (Domain-Driven Design) architecture. It generates the boilerplate — entities, value objects, use cases, repositories, controllers, migrations, and more — so you can focus on your domain logic instead of wiring.

## Installation

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

## Getting started

Create a new Vapor project scaffolded with the DDD layer structure:

```bash
mage new MyApp
cd MyApp
```

Or configure it interactively:

```bash
mage new MyApp --interactive
```

Options: `--author`, `--company`, `--license`, `--database` (postgres, mysql, sqlite), `--git`.

## Architecture

Generated projects follow a layered DDD structure:

```
Sources/App/
├── Domain/           Entities, value objects, aggregate roots, domain events
├── Application/      Use cases, DTOs, services
├── Infrastructure/   Fluent models, repository implementations, migrations
└── Interface/HTTP/   Controllers, routes, requests, responses, middleware
```

This is configured per-project in `.magerc.yml`, generated alongside the project (paths, naming conventions, and database type can all be customized there).

## Commands

Once inside a Mage-managed project, generate individual components:

| Command | Description |
|---|---|
| `mage new <name>` | Create a new Mage-managed Vapor project |
| `mage feature <name>` | Generate a complete DDD feature (entity, DTO, repository, use cases, controller, routes, migration) |
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
| `mage fluent-model <name>` | Generate a Fluent persistence model in Infrastructure |
| `mage http-request <name>` | Generate HTTP request types in Interface/HTTP/Requests |
| `mage http-response <name>` | Generate an HTTP response type in Interface/HTTP/Responses |
| `mage auth` | Generate JWT authentication scaffolding (User model, AuthController, tokens, middleware) |
| `mage test <name>` | Generate a test file for a component |
| `mage docs` | Generate API documentation scaffolding |

Run `mage help <subcommand>` for full option details, or add `--dry-run` to most generator commands to preview output without writing files.

### Example

```bash
mage entity User --fields "name:String,email:String,age:Int?"
mage repository UserRepository --entity User
mage migration CreateUser --entity User
```

## Development

```bash
swift build
swift test
```

## License

MIT
