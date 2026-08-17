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
| `Screens/Basic/` | `push`, `NavigationLink(route:)`, `present`/`cover`, `back`/`popToRoot`/`close`, `terminate()`, `RouteContext`, explicit form flow (`FormFlowScreen`/`FormScreen`) returning a typed `FormResult` via `terminate()` from both a pushed and a presented screen, `canTerminate()` guarding submission when no listener is registered, injecting `any RouterModel` into a ViewModel (`UserScreen`/`UserScreenModel`) for testability | Navigation Basics, Route Context, Testing |
| `Screens/Tabs/` | Tab-scoped stacks, per-tab `hideTabBarOnPush`, programmatic tab change (`tabRouter.change/push/update/present/cover/popToRoot`), cross-tab modal presentation, pushing into a never-visited tab, `onTabReselected`, injecting `any TabRouterModel` into a ViewModel (`ProfileScreen`/`ProfileViewModel`) for testability | Tab Navigation, Testing |
| `Screens/Split/` | `RoutingSplitView`, `select(content:)`/`select(detail:)`, `isCompact` guard on auto-selection | Split Navigation |

`AppRoute.players`/`AppRoute.form`/`AppRoute.notifications` also demonstrate nested routes and destinations: each wraps its own `Route` enum (`PlayersRoute`, `FormRoute`, `NotificationsRoute`) rendered by a dedicated destination view (`Router/Route.swift`), instead of flattening every screen into `AppRoute` directly. See Defining Routes.

`swiftroutingdemo://navigationStack/...` demonstrates a deep link selecting a navigation paradigm and performing real navigation within it — `AppDeeplinkID` mirrors `AppRoute`'s shape (reusing `NotificationsRoute` directly for `.notifications`), and `PendingDeeplinkConsumer` (`Router/Deeplink/`) defers applying the deep link until that paradigm's real `Router` has mounted. Try `swiftroutingdemo://navigationStack/user/Ben`, `swiftroutingdemo://navigationStack/notifications`, or `swiftroutingdemo://navigationStack/notifications/42` via `xcrun simctl openurl`. The other 3 paradigms (`tabView`, `tabRouter`, `splitView`) are tracked separately. See Deep Linking.

See the [main README](../../README.md#documentation) for links to each article.

## Debugging navigation

`SwiftRoutingDemoApp.swift` attaches `.printRouterOnChange()` to the root view, so every meaningful navigation event (push, present, tab change, router creation/destruction...) prints the full router tree to the console. See the full documentation's Troubleshooting article for how to read it.
