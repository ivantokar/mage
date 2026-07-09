# Getting Started

## Create a project

```bash
mage new MyApp
cd MyApp
```

Or configure it interactively:

```bash
mage new MyApp --interactive
```

Options: `--author`, `--company`, `--license`, `--database` (postgres, mysql, sqlite), `--git`.

This scaffolds a Vapor project with a layered DDD structure and a `.magerc.yml` config file that records paths and naming conventions for every generator.

## Generate your first feature

```bash
mage entity User --fields "name:String,email:String,age:Int?"
mage repository UserRepository --entity User
mage migration CreateUser --entity User
```

Or generate the whole slice at once:

```bash
mage feature Post --fields "title:String,body:String"
```

This generates the entity, DTO, repository, use cases, controller, routes, and migration together.

## Next steps

- Read the [DDD Architecture](/guide/architecture) guide to understand where generated files land.
- See [Configuration](/guide/configuration) to customize naming and paths via `.magerc.yml`.
- Browse the full [Command Reference](/api/commands).
