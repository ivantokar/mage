# Configuration (.magerc.yml)

`mage new` generates a `.magerc.yml` at the project root. Every generator reads it to decide where files go and how they're named.

```yaml
version: "1.0"
framework: vapor
architecture:
  style: ddd
  layers:
    - domain
    - application
    - infrastructure
    - interface
paths:
  sources: Sources/App
  domain: Sources/App/Domain
  application: Sources/App/Application
  infrastructure: Sources/App/Infrastructure
  persistence: Sources/App/Infrastructure/Persistence/Fluent
  interface: Sources/App/Interface/HTTP
  tests: Tests/AppTests
naming:
  repositorySuffix: Repository
  serviceSuffix: Service
  useCaseSuffix: UseCase
  controllerSuffix: Controller
  caseStyle: PascalCase
database:
  type: postgres
```

## Fields

- **paths** — where each layer's generated files are written, relative to the project root.
- **naming** — suffixes appended to generated type names (e.g. `UserRepository`, `CreateUserUseCase`) and the case style used for generated identifiers.
- **database.type** — one of `postgres`, `mysql`, `sqlite`, `mongodb`.

If `.magerc.yml` is missing, `mage` falls back to these defaults and prints a warning. Running any generator command outside a Mage-managed project (no `.magerc.yml`) fails with `Not a Mage project. Run 'mage new <name>' to create one.`
