# DDD Architecture

Mage scaffolds Vapor projects using a Clean Layered DDD structure:

```
Sources/App/
├── Domain/           Entities, value objects, aggregate roots, domain events
├── Application/      Use cases, DTOs, services
├── Infrastructure/   Fluent models, repository implementations, migrations
└── Interface/HTTP/   Controllers, routes, requests, responses, middleware
```

## Layer responsibilities

- **Domain** — the core business model. Entities, value objects, aggregate roots, and domain events live here with no framework dependencies.
- **Application** — orchestrates domain logic for a specific use case. DTOs shape data crossing the boundary; services coordinate multiple use cases or external concerns.
- **Infrastructure** — Fluent persistence models and repository implementations that satisfy domain-defined repository protocols, plus database migrations.
- **Interface/HTTP** — Vapor controllers, route collections, middleware, and HTTP request/response types that expose the application to the outside world.

## Generators map to layers

Each `mage` generator writes into the layer it belongs to:

| Layer | Generators |
|---|---|
| Domain | `entity`, `value-object`, `aggregate-root`, `domain-event` |
| Application | `use-case`, `dto`, `service` |
| Infrastructure | `repository`, `fluent-model`, `migration`, `relationship`, `seeder` |
| Interface/HTTP | `controller`, `route`, `middleware`, `http-request`, `http-response`, `auth` |

`mage feature` runs the full set for a given entity in one pass.

## Configuration

Paths and naming conventions for each layer are defined per-project in `.magerc.yml` — see [Configuration](/guide/configuration).
