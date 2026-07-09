---
layout: home

hero:
  name: "Mage CLI"
  text: "DDD Scaffolding for Vapor"
  tagline: "Generate a Clean Layered DDD Vapor project — entities, use cases, repositories, controllers, and migrations — in seconds"
  image:
    src: /mage-banner.png
    alt: Mage CLI
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: Command Reference
      link: /api/commands

features:
  - icon: 🧙
    title: Project Scaffolding
    details: "`mage new` bootstraps a Vapor project with Domain, Application, Infrastructure, and Interface layers already wired up."

  - icon: 🧱
    title: Architecture First
    details: Every generator writes into the correct DDD layer, following the conventions recorded in .magerc.yml.

  - icon: ⚡
    title: Full Feature Scaffolding
    details: "`mage feature` generates an entity, DTO, repository, use cases, controller, routes, and migration in one pass."

  - icon: 🔐
    title: Auth Scaffolding
    details: "`mage auth` generates JWT authentication — User model, AuthController, tokens, and middleware."

  - icon: 🧪
    title: Test-Aware Output
    details: "`mage test` generates matching test scaffolding for entities, repositories, use cases, controllers, and features."

  - icon: 📄
    title: Docs Generation
    details: "`mage docs` scaffolds API and architecture documentation for the generated project."
---

## Recommended Reading Order

- Project scaffolding (`mage new`)
- DDD component generators: entity, value-object, aggregate-root, service, repository, use-case, dto
- Delivery generators: controller, route, middleware, migration, relationship, seeder, auth, test, docs
- Project configuration via `.magerc.yml`

## Priority Guides

- [Getting Started](/guide/getting-started)
- [DDD Architecture](/guide/architecture)
- [Configuration](/guide/configuration)
- [Command Reference](/api/commands)
