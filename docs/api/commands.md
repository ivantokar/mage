# Commands Reference

This page lists every `mage` subcommand. Run `mage help <subcommand>` for the same detail from the CLI itself. Most generator commands support `--dry-run` to preview output without writing files.

## Project

### `mage new <project-name>`

Create a new Mage-managed Vapor project.

- `--author <name>`
- `--company <name>`
- `--license <MIT|Apache-2.0|...>`
- `--database <postgres|mysql|sqlite>` (default: `postgres`)
- `--git` — initialize a git repository
- `-i, --interactive` — prompt for the above instead of passing flags

```bash
mage new MyApp --database postgres --git
mage new MyApp --interactive
```

## Domain Layer

- `mage entity <Name>` — `--aggregate <name>`, `--fields "name:Type,..."`, `-o, --output <dir>`
- `mage value-object <Name>` — `--fields "name:Type,..."`, `-o, --output <dir>`
- `mage aggregate-root <Name>` — `--fields "name:Type"`, `-o, --output <dir>`
- `mage domain-event <Name>` — `--aggregate <name>`, `--fields "name:Type"`, `-o, --output <dir>`

```bash
mage entity User --fields "name:String,email:String,age:Int?"
mage value-object Email --fields "value:String"
mage aggregate-root Order --fields "status:String"
mage domain-event OrderPlaced --aggregate Order --fields "orderId:UUID"
```

## Application Layer

- `mage service <Name>` — `-o, --output <dir>`
- `mage repository <Name>` — `--entity <name>`, `--fields "name:Type"`, `-o, --output <dir>`
- `mage use-case <Name|Entity>` — `--entity <name>`, `--repository <name>`, `--dto <name>`, `--fields "name:Type"`, `--crud` (generate all 5 CRUD use cases), `-o, --output <dir>`
- `mage dto <Name>` — `--entity <name>`, `--fields "name:Type"`, `-o, --output <dir>`

```bash
mage repository UserRepository --entity User
mage use-case CreateUserUseCase --entity User --repository UserRepository --dto UserDTO
mage use-case User --crud --repository UserRepository --dto UserDTO
mage dto UserDTO --entity User --fields "name:String,email:String"
```

## Interface / Infrastructure

- `mage controller <Name>` — `--entity <name>`, `-o, --output <dir>`
- `mage route <Name>` — `--controller <name>`, `-o, --output <dir>`
- `mage middleware <Name>` — `-o, --output <dir>`
- `mage migration <Name>` — `--entity <name>`, `--fields "name:Type"`, `-o, --output <dir>`
- `mage relationship <Source> <Target>` — `--type <has-many|belongs-to|many-to-many>`, `-o, --output <dir>`
- `mage seeder <Name>` — `--entity <name>`, `-o, --output <dir>`
- `mage fluent-model <Entity>` — `--fields "name:Type"`, `-o, --output <dir>` (generates `<Entity>Model`)
- `mage http-request <Entity>` — `--fields "name:Type"`, `-o, --output <dir>` (generates `Create<Entity>Request`, `Update<Entity>Request`)
- `mage http-response <Entity>` — `--fields "name:Type"`, `-o, --output <dir>` (generates `<Entity>Response`)

```bash
mage controller UserController --entity User
mage route User --controller UserController
mage migration CreateUser --entity User
mage relationship User Post --type has-many
mage fluent-model User --fields "name:String,email:String"
mage http-request User --fields "name:String,email:String"
mage http-response User --fields "id:UUID,name:String"
```

## Auth, Test, and Docs

- `mage auth` — generate JWT authentication scaffolding (User model, AuthController, tokens, middleware)
- `mage test <Name>` — `--type <entity|repository|use-case|controller|feature>`, `--entity <name>`, `-o, --output <dir>`
- `mage docs [project-name]` — generate API and architecture documentation scaffolding for the project

```bash
mage auth
mage test User --type entity
mage test UserRepository --type repository --entity User
mage docs
```

## Full Feature

### `mage feature <Name>`

Generate a complete DDD feature (entity, DTO, repository, use cases, controller, routes, migration) in one pass.

- `--fields "name:Type,..."`
- `-o, --output <dir>`
- `--skip <entity,dto,repository,usecases,controller,routes,migration>` — comma-separated components to omit

```bash
mage feature Post --fields "title:String,body:String"
mage feature Comment --fields "body:String" --skip routes,migration
```
