# AGENTS

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
Load a skill only when needed:
- `npx openskills read <skill-name>`

Auto-load guidance:
- For Swift tests (`Swift Testing`, `#expect`, `#require`, flaky tests, XCTest migration), load `swift-testing-expert`.
- For Swift concurrency topics (`async/await`, actors, `@MainActor`, `Sendable`, Swift 6 migration), load `swift-concurrency`.
- For app navigation architecture using SwiftRouting, load `swift-routing`.

Local rules:
- Load and apply Markdown rules from `ai-rules/` when relevant to the current task.
- For test-related tasks, apply `ai-rules/testing.md` in priority.
</usage>

<available_skills>

<skill>
<name>swift-routing</name>
<description>SwiftRouting guidance for routes, routers, tabs, deeplinks, and troubleshooting.</description>
<location>project</location>
</skill>

<skill>
<name>swift-testing-expert</name>
<description>Expert guidance for Swift Testing, test quality, flaky tests, and XCTest migration.</description>
<location>global</location>
</skill>

<skill>
<name>swift-concurrency</name>
<description>Expert guidance for Swift Concurrency patterns, safety, and Swift 6 migration.</description>
<location>global</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
