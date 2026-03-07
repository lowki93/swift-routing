# CLAUDE.md — swift-routing

## Linear Ticket Workflow

See `ai-rules/linear_flow.md` for the full workflow.

---

## Code Conventions

- **Naming**: PascalCase for types, lowerCamelCase for properties/methods/enum cases
- **Access control**: `public` only for exposed APIs, `private`/`internal` by default
- **Concurrency**: `@MainActor` on main types, `@unchecked Sendable` for thread-safe classes
- **Public classes**: `public final class`
- **Doc comments**: `///` with Swift code examples on all public types and methods

## Versioning

See `ai-rules/versionning.md` for the full branch, commit, and PR conventions.

## Tests

See `ai-rules/testing.md` for the full rules.

Summary:
- Framework: Swift Testing (`import Testing`, `@Test`, `#expect`)
- Structure: `struct` per domain, `enum` to group behaviors
- Naming: `givenX_whenY_thenZ` or `stateDescription_return_result`
- Command: `swift test`

## Available Skills

See `AGENTS.md` for the full skills system.

Auto-load:
- Test task → `swift-testing-expert` + `ai-rules/testing.md`
- Navigation/routing task → `swift-routing`
- Concurrency task → `swift-concurrency`
- DocC documentation task → `swift-docc-documentation`

## Linear Project

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
