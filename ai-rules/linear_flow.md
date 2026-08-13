# Linear Flow (SwiftRouting)

This file defines the workflow to follow when working on a Linear ticket.

## Workflow

1. **Read the ticket** — fetch title, description, labels via the Linear MCP
2. **Pull `main`** — `git checkout main && git pull origin main`
3. **Create a branch** from `main` — see `ai-rules/versionning.md` for branch naming
4. **Explore the code** before making any changes
5. **Write a plan** and present it for approval — do not start implementing until the user explicitly approves it. Be as detailed as possible to make the review easy:
   - Files/modules that will be created or modified
   - Concrete steps/changes for each file (not just "update X")
   - Edge cases or tricky parts you identified while exploring
   - Open questions or assumptions, if any
6. **Implement** following the project conventions
7. **Run tests**: `swift test`
8. **Commit** — see `ai-rules/versionning.md` for commit format
9. **Push + create PR** — see `ai-rules/versionning.md` for PR format

> Ticket states are updated automatically via the Linear ↔ GitHub integration.

## Project Context

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
