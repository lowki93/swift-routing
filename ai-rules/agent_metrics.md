# Agent Metrics (SwiftRouting)

This file defines how the quality of the agents is recorded and measured.

## Purpose

Decide where agents can get more autonomy and where they need more control. For example: if plans are approved on the first try for documentation tickets, the plan gate can be lighter for that ticket type; if the CI review has low precision, the review skill needs tightening.

The signals come from what already exists (PRs, commits, review threads, reactions), with as little manual input as possible. `scripts/agent-metrics.py` aggregates them on demand.

## What is measured

- **CI review** (`@claude_review`): findings posted by the bot, 👍 / 👎 votes on them, findings fixed (thread has a "Fixed in <sha>" reply), probable noise (resolved without a "Fixed in" reply, or 👎), and human threads after review (threads opened by a person other than the PR author after the bot's first comment on the same PR). Those may include problems the bot missed: read them. Votes from the PR author and from bots are ignored.

"Probable noise" also includes threads a human resolved after fixing by hand without a follow-up `@claude_review` (so no "Fixed in" reply): don't over-trust it.
- **Linear flow** (`planner` → `dev` → `reviewer`): the **Agent metrics** section of the PR body, described below.
- **Human fixups**: on agent-written PRs (at least one commit with a `Co-Authored-By: Claude` trailer), the commits without that trailer. Nothing to fill in, the script counts them (merge commits are ignored). Linear-flow PRs are highlighted in the table.

## PR body section

Required for Linear ticket flow PRs, omitted otherwise. Individual keys stay optional: omit a key when its value is unknown.

```
**Agent metrics**:
- plan: rounds=2; changes=scope,api
- dev: test_failures=1; stopped=no
- reviewer: blocking=0; should_fix=3; nit=2; fixed=4; skipped=1
```

| Field | Meaning |
|---|---|
| `plan.rounds` | Number of plan proposals before approval. `1` = approved on the first try. |
| `plan.changes` | What the user had the plan change: `scope`, `api`, `naming`, `docs`, `tests`, `structure`, `other`, or `none`. Comma-separated. Unknown values count as `other`. |
| `dev.test_failures` | Number of test runs that failed before they went green. |
| `dev.stopped` | `yes` / `no`: did `dev` stop to ask for a decision. |
| `reviewer.blocking`, `should_fix`, `nit` | Findings per severity. |
| `reviewer.fixed`, `skipped` | How many findings were fixed and how many were skipped. Skipped ones are detailed in **Review notes**. |

## Who fills it

The main session, when it creates the PR (step 7 of `ai-rules/linear_flow.md`), from facts it already knows. Never guess: omit a key when its value is unknown.

## Rating CI review findings

Maintainers react 👍 (useful) or 👎 (noise) on each inline comment posted by the Claude bot. Votes from the PR author are ignored. The script uses those votes for precision, and falls back to fixed / findings when there are none.

## Running the script

```bash
python3 scripts/agent-metrics.py                      # last 30 days, Markdown
python3 scripts/agent-metrics.py --since 2026-11-01   # from a date
python3 scripts/agent-metrics.py --json               # raw aggregates
python3 scripts/agent-metrics.py --self-test          # check the parsing and classification
```

Time windows:

- The Linear-flow section uses PRs merged since the date (`merged:>=since`).
- The CI review section uses PRs updated since the date (`updated:>=since`, open or closed), because external PRs often stay open for a long time.

The script warns on stderr when a list may be truncated (200 PRs, 100 threads per PR, 50 comments per thread).

It needs the `gh` CLI, authenticated. `--repo OWNER/NAME` overrides the repository detected from the current directory.
