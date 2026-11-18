# Contributing

## GitHub issues are the source of truth

There is no separate specification in the repository. Design, scope and
acceptance criteria live in GitHub issues, and the code is checked against them.

- **Design first, in an issue.** A feature or a contract change starts as an
  issue that states the problem, the proposed behavior and a checklist of
  requirements. The architecture contracts are #17–#29.
- **Verify against the issue.** A pull request names the issue it implements
  (`for #N` when it is a slice, `part of #N` when more is coming) and is checked
  against that issue's checklist. If the implementation changes the design,
  update the issue in the same step.
- **Close an issue when its checklist is met**, with a comment that links the
  pull requests that did it. Work deliberately left out moves to a new or
  existing issue; do not leave it as an unchecked box in a closed one.
- **Umbrella issues** (`roadmap`) hold the release gates and the order of work.
  The vNext roadmap is #30, with one implementation issue per phase. Tick a gate
  only after checking it against the code.
- **The README and the CHANGELOG describe what the code does today.** They are
  not a place for plans: plans belong in issues.
- A capability is **supported** only when it is implemented, its generated
  output is validated, `mage doctor` covers it, a fixture exercises it, and
  `swift build` and `swift test` pass. Anything else is planned or experimental.

## Labels

- Release scope: `next-major` (required before 1.0), `roadmap` (umbrella).
- Work type: `architecture`, `testing`, `cleanup`, `integration`, plus GitHub's
  `enhancement`, `bug` and `documentation`.
- Ownership: one or more `area:*` labels (`area:core`, `area:cli`,
  `area:project`, `area:doctor`, `area:domain`, `area:application`,
  `area:persistence`, `area:http`, `area:composition`, `area:release`).

## Pull requests

- Branch from, and target, the release branch named in the roadmap issue
  (currently `release/1.0`), not `main`.
- Answer the per-PR quality checklist from #30.
- Prefer focused tests around generation plans, diagnostics, and fixtures.
- Open a pull request as a draft while it is still changing.
- Commit messages and pull request descriptions are plain text; do not add
  attribution trailers.
- Do not commit machine-specific files (for example `.claude/settings.local.json`).
