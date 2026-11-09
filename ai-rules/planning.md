# Planning Rules (SwiftRouting)

This file defines how to plan a task before implementing it.

## Process

1. **Delegate exploration + drafting** to the `planner` custom subagent (`.claude/agents/planner.md`; model and effort in `ai-rules/linear_flow.md`) via the Agent tool with `subagent_type: "planner"`. The main thread stays on its own model.
2. **Submit the plan for approval** via plan mode (`ExitPlanMode`).
3. **Do not start implementing** until the user explicitly approves the plan.

## Plan Content

Be as detailed as possible to make the review easy:

- Files/modules that will be created or modified
- Concrete steps/changes for each file (not just "update X")
- Edge cases or tricky parts identified while exploring
- Open questions or assumptions, if any
