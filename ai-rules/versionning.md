# Versioning Rules (SwiftRouting)

This file defines the git process (pull, branch, commit, push, PR) and the branch, commit, and PR conventions for the project.

## Process

1. **Pull `main`** — `git checkout main && git pull origin main`
2. **Create a branch** from `main` — see Branch Naming below
3. Implement, then **run tests**: `swift test`
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
