# Planning Rules (SwiftRouting)

This file defines how to plan a task before implementing it.

## Process

1. **Delegate exploration + drafting** to the `plan-opus48` custom subagent (`.claude/agents/plan-opus48.md`, pinned to `claude-opus-4-8`) via the Agent tool with `subagent_type: "plan-opus48"`. This gives good planning quality at Opus 4.8 cost, without manual `/model` switching — the main thread stays on the default model. (Note: the Agent tool's `model` override param only accepts family aliases — `opus`, `sonnet`, `haiku`, `fable` — not a specific version like 4.8; pinning requires a custom agent definition.)
2. **Submit the plan for approval** via plan mode (`ExitPlanMode`).
3. **Do not start implementing** until the user explicitly approves the plan.

## Plan Content

Be as detailed as possible to make the review easy:

- Files/modules that will be created or modified
- Concrete steps/changes for each file (not just "update X")
- Edge cases or tricky parts identified while exploring
- Open questions or assumptions, if any
