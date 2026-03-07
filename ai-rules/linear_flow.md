# Linear Flow (SwiftRouting)

This file defines the workflow to follow when working on a Linear ticket.

## Workflow

1. **Read the ticket** — fetch title, description, labels via the Linear MCP
2. **Create a branch** from `main` — see `ai-rules/versionning.md` for branch naming
3. **Explore the code** before making any changes
4. **Implement** following the project conventions
5. **Run tests**: `swift test`
6. **Commit** — see `ai-rules/versionning.md` for commit format
7. **Push + create PR** — see `ai-rules/versionning.md` for PR format

> Ticket states are updated automatically via the Linear ↔ GitHub integration.

## Project Context

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
