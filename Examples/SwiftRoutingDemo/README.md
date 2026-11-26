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
| `Screens/Basic/` | `push`, `NavigationLink(route:)`, `present`/`cover`, `pop`/`popToRoot`/`close`, `terminate()`, `RouteContext`, explicit form flow (`FormFlowScreen`/`FormScreen`) returning a typed `FormResult` via `terminate()` from both a pushed and a presented screen, `canTerminate()` guarding submission when no listener is registered, `SettingsScreen` using a payload-free `ChoiceReset` context + `terminate()` to reset the paradigm and return to the picker, injecting `any RouterModel` into a ViewModel (`UserScreen`/`UserScreenModel`) for testability | Navigation Basics, Route Context, Testing |
| `Screens/Tabs/` | Tab-scoped stacks, per-tab `hideTabBarOnPush`, programmatic tab change (`tabRouter.change/push/update/present/cover/popToRoot`), cross-tab modal presentation, pushing into a never-visited tab, `onTabReselected`, injecting `any TabRouterModel` into a ViewModel (`ProfileScreen`/`ProfileViewModel`) for testability | Tab Navigation, Testing |
| `Screens/Split/` | `RoutingSplitView`, `select(content:)`/`select(detail:)`, `isCompact` guard on auto-selection, deep linking into both the 2-column and 3-column layouts (`PlayerSplitDeeplinkHandler`/`PlayerListDeeplinkHandler`) | Split Navigation |

`AppRoute.players`/`AppRoute.form`/`AppRoute.notifications` also demonstrate nested routes and destinations: each wraps its own `Route` enum (`PlayersRoute`, `FormRoute`, `NotificationsRoute`) rendered by a dedicated destination view (`Router/Route.swift`), instead of flattening every screen into `AppRoute` directly. See Defining Routes.

`swiftroutingdemo://navigationStack/...` demonstrates a deep link selecting a navigation paradigm and performing real navigation within it. `AppDeeplinkID` mirrors `AppRoute`'s shape, but each identifier (`UserDeeplinkID`, `NotificationsDeeplinkID`) is its own type with its own composable parser (`Router/Deeplink/`) rather than reusing `AppRoute`'s nested `Route` types directly — the deep link's shape is a URL-facing concern, kept separate from the internal route shape. `PendingDeeplinkConsumer` (navigation stack) and `PendingTabDeeplinkConsumer` (plain `TabView`) defer applying the deep link until that paradigm's real `Router` has mounted; `PendingTabRouterDeeplinkConsumer` does the same for `RoutingTabView`, delegating tab selection to `TabRouter.handle(tabDeeplink:)` instead of tracking it separately. `PendingSplitDeeplinkConsumer` does the same for `SplitView`, via `Router.handle(splitDeeplink:)` -- and since `SplitScreen`'s 2-column and 3-column layouts have different content/detail column shapes (`SplitDeeplink<Never, PlayerType, AppRoute>` vs `SplitDeeplink<PlayerType, Player.ID, AppRoute>`), it picks the handler matching whichever layout is active rather than forcing a switch. See Deep Linking.

See the [main README](../../README.md#documentation) for links to each article.

## Navigation restoration

The demo comes back to the same state after the app is killed and relaunched. `RootScreen` holds one root `Router` per window and applies `.navigationRestoration()` before `.environment(\.router, ...)`; the stacks, sheets, tabs and splits underneath are saved when the scene leaves the foreground and restored on the next launch.

What makes it work in the demo:

- Routes and tab routes (`AppRoute`, `PlayersRoute`, `FormRoute`, `NotificationsRoute`, `HomeTab`) are `Codable`.
- Routes and selections carry stable identifiers, not models: `PlayersRoute.detail` takes a `Player.ID`, and players have fixed ids (a `UUID()` per launch would not resolve after a relaunch). `PlayerType` is `Codable`.
- `ChoiceScreen` persists the selected example with `@SceneStorage`, and `SplitScreen` persists its 2-column or 3-column layout. Both layouts share the restoration key `split(Sidebar)` but use different data types, so the layout must come back with the navigation.
- The sidebar and the players list do not auto-select a different value when a selection was restored (that would count as a selection change and drop the restored nested state).
- The "Reset saved state" button calls `router.clearNavigationRestoration()` and returns to the choice screen.

To try it:

1. Run the app on a simulator from Xcode, pick an example (for instance **RoutingTabView**), switch to another tab, push a screen and present a sheet. For **SplitView**, pick a player and push a screen in the detail column.
2. Send the app to the background (Home, or `Shift+Cmd+H`). The state is saved when the scene leaves the foreground.
3. Stop the app from Xcode (Stop button), then run it again. The same example, tab, stack and sheet come back without a flash.
4. Closing the app from the app switcher starts fresh, because the system discards the scene's saved state.
5. Tap **Reset saved state**, background the app, stop and relaunch: the app starts on the choice screen with the default layout.

On iPad, open two windows to see that each one restores independently. A deeplink opened at launch is applied on top of the restored state.

## Testing deep links

With the app installed on a booted simulator:

```bash
# User screen
xcrun simctl openurl booted "swiftroutingdemo://navigationStack/user/Ben"

# Notifications list
xcrun simctl openurl booted "swiftroutingdemo://navigationStack/notifications"

# Notifications detail (nested route)
xcrun simctl openurl booted "swiftroutingdemo://navigationStack/notifications/42"

# Profile, presented as a sheet
xcrun simctl openurl booted "swiftroutingdemo://navigationStack/profile"

# Unmatched -- should log "no match", not crash
xcrun simctl openurl booted "swiftroutingdemo://navigationStack/doesnotexist"

# TabView: selects the Notifications tab
xcrun simctl openurl booted "swiftroutingdemo://tabView/notifications"

# TabView: Notifications tab, detail pushed
xcrun simctl openurl booted "swiftroutingdemo://tabView/notifications/42"

# TabView: selects the Profile tab
xcrun simctl openurl booted "swiftroutingdemo://tabView/profile"

# TabView: Home tab (default for .user), User(Ben) pushed
xcrun simctl openurl booted "swiftroutingdemo://tabView/user/Ben"

# RoutingTabView: selects the Notifications tab
xcrun simctl openurl booted "swiftroutingdemo://tabRouter/notifications"

# RoutingTabView: Notifications tab, detail pushed
xcrun simctl openurl booted "swiftroutingdemo://tabRouter/notifications/42"

# RoutingTabView: selects the Profile tab
xcrun simctl openurl booted "swiftroutingdemo://tabRouter/profile"

# RoutingTabView: Home tab (default for .user), User(Ben) pushed
xcrun simctl openurl booted "swiftroutingdemo://tabRouter/user/Ben"

# SplitView: selects the Footballer content column (no specific player)
xcrun simctl openurl booted "swiftroutingdemo://splitView/players/footballer"

# SplitView: Footballer content, "Erling Haaland" selected in the detail column
xcrun simctl openurl booted "swiftroutingdemo://splitView/players/footballer/Erling%20Haaland"

# SplitView: Basketball content, "LeBron James" selected in the detail column
xcrun simctl openurl booted "swiftroutingdemo://splitView/players/basketballPlayer/LeBron%20James"
```

Each one selects the paradigm (if not already selected) and navigates to the target screen -- for `tabView`/`tabRouter`, that includes switching to the right tab. `splitView` adapts to whichever column layout is currently active: in 3-column mode it selects both the content (type) and detail (player) columns; in 2-column mode it selects the player list for that type and pushes the specific player within it -- toggle the layout from the Sidebar's "Configuration" menu before firing the URL to try the other mode. Note: `xcrun simctl openurl` only reliably delivers one `.onOpenURL` event per app launch session in the Simulator -- terminate and relaunch the app (or use `xcrun simctl launch` to bring it back to the foreground) between tries if a later URL seems to have no effect.

## Testing

The `SwiftRoutingDemoTests` unit-test target shows how to unit-test navigation without exercising any UI. It links the local `SwiftRoutingTestSupport` product and uses its spies in place of the real routers:

- `UserScreenModelTests` — `RouterSpy` injected as `any RouterModel` (`pushBen()`/`pop()`/`popToRoot()`)
- `ProfileViewModelTests` — `TabRouterSpy` injected as `any TabRouterModel` (`presentSearch()`/`coverAbout()`/`presentSearchInNotifications()`/`resetHomeTab()`)

Both follow the patterns in the Testing article ("Strategy 1: RouterSpy" and "Strategy 2: Test ViewModel Navigation"). Run them from Xcode with the `SwiftRoutingDemo` scheme (⌘U), or from the command line on any supported platform:

```bash
xcodebuild test -project SwiftRoutingDemo.xcodeproj -scheme SwiftRoutingDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'

xcodebuild test -project SwiftRoutingDemo.xcodeproj -scheme SwiftRoutingDemo \
  -destination 'platform=macOS'
```

## Debugging navigation

`SwiftRoutingDemoApp.swift` attaches `.printRouterOnChange()` to the root view, so every meaningful navigation event (push, present, tab change, router creation/destruction...) prints the full router tree to the console. See the full documentation's Troubleshooting article for how to read it.
