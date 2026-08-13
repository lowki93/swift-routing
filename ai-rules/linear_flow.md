# Linear Flow (SwiftRouting)

This file defines the workflow to follow when working on a Linear ticket.

## Workflow

1. **Read the ticket** — fetch title, description, labels via the Linear MCP
2. **Pull `main` and create a branch** — see `ai-rules/versionning.md` for branch naming. Do this before exploring, so exploration happens on a clean, up-to-date state.
3. **Explore the code** before making any changes
4. **Plan** — see `ai-rules/planning.md` for how to draft and get approval on the implementation plan
5. **Implement** following the project conventions, then **run tests**: `swift test`
6. **Commit, push, and create PR** — see `ai-rules/versionning.md` for commit and PR conventions

> Ticket states are updated automatically via the Linear ↔ GitHub integration.

## Project Context

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
