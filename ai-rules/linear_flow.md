# Linear Flow (SwiftRouting)

This file defines the workflow to follow when working on a Linear ticket.

## Workflow

1. **Read the ticket** — fetch title, description, labels via the Linear MCP
2. **Pull `main` and create a branch** — see `ai-rules/versionning.md` for branch naming. Do this first, so everything after happens on a clean, up-to-date state.
3. **Skim the code** — only enough to brief the `planner` well; the in-depth exploration is its job
4. **Plan** — see `ai-rules/planning.md` for how to draft and get approval on the implementation plan
5. **Implement** — delegate to the `dev` subagent with the approved plan. It follows the project conventions and runs the tests (`swift test --filter <target>` per target).
6. **Review** — before any PR, run the `reviewer` subagent. Give it **no context**: only ask it to review the changes against `main`. It reviews uncommitted changes too (`git diff $(git merge-base main HEAD)` + untracked files), so it can run before the commit. It does a pure Swift code review (correctness, idioms, clean code, conventions).
   - Fix the relevant findings through `dev`, re-run the tests, and run `reviewer` again if the fixes were significant.
   - Findings you choose not to fix go in the PR body's **Review notes** section, with the reason (see `ai-rules/versionning.md`).
7. **Commit, push, and create PR** — see `ai-rules/versionning.md` for commit and PR conventions

## Subagents

Defined in `.claude/agents/`. This table and each agent's frontmatter are the only places that state model and effort.

| Step | Subagent | Model | Effort |
|---|---|---|---|
| Plan | `planner` | `claude-opus-5-5` | high |
| Implement | `dev` | `claude-sonnet-5-5` | not set — inherits the session's effort |
| Review | `reviewer` | `claude-opus-5-5` | medium |

> Ticket states are updated automatically via the Linear ↔ GitHub integration.

## Project Context

- Workspace: `swift-routing`
- Team: `Swift-Routing`
- Project: `Plan d'amélioration`
- Tickets: SWI-5 to SWI-19
- Recommended order: T1 → T2 → D1 → D2 → E1 → E2 → rest
