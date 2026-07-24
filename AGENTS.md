# AGENTS

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
Load a skill only when needed:
- Project skills (`location: project`): `npx skills use lowki93/swift-routing --skill <skill-name>`
- Global skills (`location: global`): already installed at `~/.claude/skills/<skill-name>/SKILL.md` — read it directly; reinstall with `npx skills add <source> --skill <skill-name> -g` if missing (see `<source>` per skill below)

Auto-load guidance:
- For Swift tests (`Swift Testing`, `#expect`, `#require`, flaky tests, XCTest migration), load `swift-testing-expert`.
- For Swift concurrency topics (`async/await`, actors, `@MainActor`, `Sendable`, Swift 6 migration), load `swift-concurrency`.
- For app navigation architecture using SwiftRouting, load `swift-routing`.
- For migration from native NavigationStack to SwiftRouting, load `swift-routing` **and** `swift-routing-migration`.

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
<source>avdlee/swift-testing-agent-skill</source>
</skill>

<skill>
<name>swift-concurrency</name>
<description>Expert guidance for Swift Concurrency patterns, safety, and Swift 6 migration.</description>
<location>global</location>
<source>avdlee/swift-concurrency-agent-skill</source>
</skill>

<skill>
<name>swift-docc</name>
<description>Official Swift DocC documentation markup and syntax reference.</description>
<location>global</location>
<source>nonameplum/agent-skills</source>
</skill>

<skill>
<name>swift-routing-migration</name>
<description>Step-by-step guidance for migrating from native NavigationStack to SwiftRouting.</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
