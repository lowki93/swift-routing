# Linear Flow (SwiftRouting)

This file defines the workflow to follow when working on a Linear ticket.

## Workflow

1. **Read the ticket** — fetch title, description, labels via the Linear MCP
2. **Pull `main` and create a branch** — see `ai-rules/versionning.md` for branch naming. Do this before exploring, so exploration happens on a clean, up-to-date state.
3. **Explore the code** before making any changes
4. **Plan** — see `ai-rules/planning.md` for how to draft and get approval on the implementation plan
5. **Implement** — delegate to the `dev` subagent (`.claude/agents/dev.md`, `claude-sonnet-5-5`) with the approved plan. It follows the project conventions and runs the tests (`swift test --filter <target>` per target).
6. **Review** — before any PR, run the `reviewer` subagent (`.claude/agents/reviewer.md`, `claude-opus-5-5`, `effort: medium`). Give it **no context**: only ask it to review the branch diff against `main`. It does a pure Swift code review (correctness, idioms, clean code, conventions).
   - Fix the relevant findings through `dev`, re-run the tests, and run `reviewer` again if the fixes were significant.
   - Findings you choose not to fix are listed with the reason in the PR body.
7. **Commit, push, and create PR** — see `ai-rules/versionning.md` for commit and PR conventions

## Subagents

| Step | Subagent | Model | Effort |
|---|---|---|---|
| Plan | `planner` | `claude-opus-5-5` | high |
| Implement | `dev` | `claude-sonnet-5-5` | session default |
| Review | `reviewer` | `claude-opus-5-5` | medium |

> Ticket states are updated automatically via the Linear ↔ GitHub integration.

## Project Context

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
