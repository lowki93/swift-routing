# SwiftRoutingDemo

An Xcode project demonstrating SwiftRouting's navigation patterns. Open `SwiftRoutingDemo.xcodeproj` and run it on iOS or macOS.

## Running it

`ChoiceScreen` (the app's entry point) lets you pick which navigation setup to explore:

- **Navigation Stack** — a single `RoutingView`/`NavigationStack`
- **TabView** — plain SwiftUI `TabView`, each tab with its own `RoutingView`
- **RoutingTabView** — SwiftRouting's tab container, with cross-tab navigation via `TabRouter`
- **SplitView** — `RoutingSplitView` (sidebar/content/detail)

## What each section demonstrates

| Folder | Demonstrates | Related article |
|---|---|---|
| `Screens/Basic/` | `push`, `NavigationLink(route:)`, `present`/`cover`, `back`/`popToRoot`/`close`, `terminate()`, `RouteContext`, explicit form flow (`FormFlowScreen`/`FormScreen`) returning a typed `FormResult` via `terminate()` from both a pushed and a presented screen, `canTerminate()` guarding submission when no listener is registered | Navigation Basics, Route Context |
| `Screens/Tabs/` | Tab-scoped stacks, per-tab `hideTabBarOnPush`, programmatic tab change (`tabRouter.change/push/update/present/cover/popToRoot`), cross-tab modal presentation, pushing into a never-visited tab, `onTabReselected` | Tab Navigation |
| `Screens/SplitScreen.swift`, `SidebarScreen.swift`, `Players(Screen).swift`, `PlayerScreen.swift` | `RoutingSplitView`, `select(content:)`/`select(detail:)` | Split Navigation |

See the [main README](../../README.md#documentation) for links to each article. Deep linking isn't demonstrated yet (tracked separately).

## Debugging navigation

`SwiftRoutingDemoApp.swift` attaches `.printRouterOnChange()` to the root view, so every meaningful navigation event (push, present, tab change, router creation/destruction...) prints the full router tree to the console. See the full documentation's Troubleshooting article for how to read it.
