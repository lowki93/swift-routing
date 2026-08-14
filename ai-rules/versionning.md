# Versioning Rules (SwiftRouting)

This file defines the git process (pull, branch, commit, push, PR) and the branch, commit, and PR conventions for the project.

## Process

1. **Pull `main`** — `git checkout main && git pull origin main`
2. **Create a branch** from `main` — see Branch Naming below
3. *(implementation happens here — see `ai-rules/planning.md` and `CLAUDE.md`)*
4. **Commit** — see Commit Conventions below
5. **Push + create PR** — see PR Conventions below

## Branch Naming

Format: `type/SWI-XX-short-title`

| Type | Prefix |
|---|---|
| Feature | `feat/` |
| Bug fix | `fix/` |
| Improvement | `impr/` |
| Documentation | `feat/` |

Example: `feat/SWI-5-navigation-link-tests`

## Multi-Ticket Epics

If a parent ticket has sub-tickets that are **not independently shippable** (e.g. an early sub-ticket makes a founding/breaking decision, or the work leaves the code in a non-functional intermediate state until a later sub-ticket lands), don't branch each sub-ticket from `main`. Instead:

1. Create one integration branch from `main`: `feat/SWI-XX-<slug>` (using the parent ticket's number).
2. Branch each sub-ticket from that integration branch, and PR into it instead of `main`.
3. Merge the integration branch into `main` only once the epic is complete (all sub-tickets done).

This does **not** apply just because a ticket is large — a parent ticket whose sub-tickets are each independently shippable (e.g. SWI-44's demo-app sub-tickets, each adding a self-contained screen) still branches every sub-ticket from `main` as usual.

## Commit Conventions

Format: `short description`

Example: `add NavigationLink extension tests`

- No ticket number required.
- No type prefix required.
- Keep the message short and descriptive.

## PR Conventions

- **Title** format: `type(scope): [SWI-XX] description` (always written in English)
- **Body** must follow this template (always written in English):

```
**What**:
Clear summary of what this PR accomplishes

**Breaking Changes**:
Highlight any API, public interface, or dependency changes
```

Types: `feat`, `fix`, `update`, `impr`, `revert`

Example title: `feat(tests): [SWI-5] add NavigationLink extension tests`
