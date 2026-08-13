# Planning Rules (SwiftRouting)

This file defines how to plan a task before implementing it.

## Process

1. **Delegate exploration + drafting** to the `Plan` subagent with `model: "opus"` (via the Agent tool). This gives Opus-level planning quality automatically, without manual `/model` switching — the main thread stays on the default model.
2. **Submit the plan for approval** via plan mode (`ExitPlanMode`).
3. **Do not start implementing** until the user explicitly approves the plan.

## Plan Content

Be as detailed as possible to make the review easy:

- Files/modules that will be created or modified
- Concrete steps/changes for each file (not just "update X")
- Edge cases or tricky parts identified while exploring
- Open questions or assumptions, if any
