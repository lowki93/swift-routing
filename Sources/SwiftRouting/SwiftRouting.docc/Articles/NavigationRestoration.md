# Navigation Restoration

Bring the user back to the same screens after the system killed your app in the background.

## Overview

When the system kills a backgrounded app, SwiftUI relaunches it on the default screens. With navigation restoration, SwiftRouting saves the navigation of each window when the app leaves the foreground, and rebuilds it before the first frame on the next launch: the selected tab, every stack, the sheets and covers that were open, and the selections of a split view.

Restoration is **opt-in** and automatic once enabled. Without the modifier, nothing is checked, logged or written, and your app behaves exactly as before.

What is saved is the route values (and the selected tab and split selections), never a view's own state, a scroll position or a ``RouteContext`` closure.

## Enabling Restoration

Apply `navigationRestoration(_:)` once per scene, at the root of the scene, **before** `.environment(\.router, ...)`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var router = Router(configuration: .default)

    var body: some View {
        RoutingView(destination: HomeRoute.self, root: .home)
            .navigationRestoration()
            .environment(\.router, router)
    }
}
```

The modifier reads the root router from the environment, so `.environment(\.router, ...)` must come after it in the modifier chain (applied further out), exactly like `printRouterOnChange()` (see <doc:Troubleshooting>).

> Important: Apply it at the root only. Below the root (inside a screen, a sheet or a tab), the modifier is a silent no-op: the root's modifier is the only one that saves and restores.

The optional `key` names the saved state. Most apps never need it. Changing the key reads another slot, so the next launch starts fresh; this is also a way to reset the saved state after an incompatible release.

```swift
.navigationRestoration("v2")
```

### One Root Router per Window

Create one root ``Router`` per window and inject it with `.environment(\.router, ...)`, as `RootView` does above. Each window then has its own saved state and restores its own navigation.

Never rely on the environment default: without an injected router, every window falls back to the same shared default router, and their navigation would be mixed.

## What Is Restored

| Container | Restored |
|-----------|----------|
| ``RoutingView`` | Root route, pushed routes (with their `inStack` flag) |
| Sheets and covers | The open sheet or cover, with its own stack, recursively (a sheet in a sheet) |
| ``TabRouter`` / ``RoutingTabView`` | The selected tab, from the first frame and without a reselect (no `popToRoot`). The caller's `tab` binding is updated |
| ``RoutingSplitView`` | Content selection, detail selection and the detail stack |

A plain `TabView` without a ``TabRouter`` does not restore its selected tab; the stacks inside its tabs are still restored. Tabs the user never visited keep their saved stack: a save never wipes what was not built.

Never saved: route contexts, a modal that is still pending or dismissing, closures and any view state.

## Making Your Types Codable

A container is restored only when every type it needs is `Codable`:

- the route type, including the associated values of every case;
- the routes nested inside associated values;
- the tab type of a ``TabRouter``;
- the route type, `ContentData` and `DetailData` of a ``RoutingSplitView`` (`Never` is `Codable`, so a 2-column split qualifies).

```swift
enum HomeRoute: Route, Codable {
    case home
    case detail(id: Int)
    case settings

    var name: String {
        switch self {
        case .home: "home"
        case .detail(let id): "detail(\(id))"
        case .settings: "settings"
        }
    }
}
```

Tab types follow the same rule:

```swift
enum HomeTab: TabRoute, Codable {
    case home
    case settings

    var name: String {
        switch self {
        case .home: "home"
        case .settings: "settings"
        }
    }
}
```

The check happens at runtime when the container is created, so no API changes: a route type that is not `Codable` still works, its container is simply not restored (see <doc:NavigationRestoration#When-Something-Cannot-Be-Restored>).

### Prefer Stable Identifiers Over Models

A saved route is a copy of its values at the time of the save. If a route carries a full model, the model is saved too, and comes back stale or no longer matches your data. Pass a stable identifier and load the model when the screen appears:

```swift
// ❌ A snapshot of the user, written to disk and restored as it was
case profile(User)

// ✅ A stable identifier, the screen loads the current user
case profile(userID: String)
```

Avoid identifiers that change between launches (for example a freshly generated `UUID()`): the restored route would point to nothing.

### Container Identity

Each container is saved under its identity in the router tree: its router type and the `name` of its root route (`stack(home)`, `tab(settings)`, `split(sidebar)`, `presented(editor)`, plus the sheet or cover slot of a modal), and the tab type name for a ``TabRouter``. Keep these names stable between releases, and distinct between siblings.

Two siblings sharing an identity are not saved, and a `duplicateKey` error is logged once. Two splits that share the same sidebar route name but have different data types (for example a 2-column and a 3-column layout) decode each other's state with the wrong types: the result is a `decodingFailed` error and the default state.

## When State Is Saved and Discarded

The saved state follows the semantics of SwiftUI's scene storage:

- **Saved** when the scene leaves the foreground (it stops being `.active`): the state saved is the one the user last saw.
- **Restored** the next time the scene is created after the system killed the app in the background.
- **Discarded** when the user closes the app from the app switcher: the next launch starts on the default screens.
- **Per window**: each iPad or Mac window has its own saved state.

> Note: A system kill is hard to trigger by hand. Send the app to the background, stop it from Xcode, then relaunch it from the home screen to check the restored state.

## Deeplinks Are Applied on Top

Restoration happens while the containers are created, before your deeplink handling runs. When the app is opened by a deeplink, the restored state is rebuilt first, then the deeplink is applied on top exactly as without restoration: `handle(deeplink:)` closes the open modals and starts from the root (see <doc:Deeplinks>). A restored modal is closed even when its router was not built yet.

## When Something Cannot Be Restored

Restoration never crashes your app because of a bad snapshot. Failures are scoped to a container: the container, and everything inside it, starts on its default state, while the other containers are restored normally. Each failure is logged once as an error through the configured logger, as ``RouterError/restoration(_:)``.

| Reason | When | Result |
|--------|------|--------|
| `notCodable` | The container's route types are not `Codable` | The container starts on its default state and is never saved |
| `decodingFailed` | The saved state no longer decodes (a renamed or removed case, a type change), or the whole saved data is corrupt or from an unknown version | The container and its subtree start on their default state. Corrupt data or an unknown version discards the whole snapshot |
| `encodingFailed` | A route could not be encoded when saving (for example a route of another type pushed in the stack) | The container's own state is not saved, its children still are |
| `duplicateKey` | Sibling containers share the same identity | None of them is saved |

A saved tab that no longer decodes (a removed case) only costs the selection: the tab starts on the one passed to the view, and the stacks of the tabs are restored.

Observe the failures in your logger. The closure receives a ``LoggerConfiguration``:

```swift
let configuration = Configuration(
    logger: { loggerConfiguration in
        guard case .error(.restoration(let reason)) = loggerConfiguration.message else { return }
        switch reason {
        case .notCodable(let container, let type):
            print("\(container) is not restored: \(type) is not Codable")
        case .decodingFailed(let container, let error):
            print("\(container) starts on its default state: \(error)")
        case .encodingFailed(let container, let error):
            print("\(container) is not saved: \(error)")
        case .duplicateKey(let container):
            print("Several routers share \(container)")
        }
    },
    shouldCrashOnRouteNotFound: false
)
```

> Important: ``RouterError`` has a new case, `restoration(_:)`. Any exhaustive `switch` over `RouterError` must handle it, or add a `default`.

### Crashing on a Non-Codable Container

`Configuration.shouldCrashOnRouteNotFound` has one extra effect when restoration is enabled: a container whose route types are not `Codable` triggers a `fatalError` instead of a log, so you find the forgotten conformance during development. This is the only restoration failure that can crash. A saved state that fails to decode, a corrupt snapshot or a renamed case never does, even with the flag on. Without the modifier the flag keeps its original meaning only. See <doc:ConfigurationGuide>.

## Containers Nested in a Screen

A stack, split or modal can be created from a screen of another stack (a `RoutingView` inside a pushed screen, a `TabRouter` in a detail). Its saved state is only valid while that screen is still the one it was saved under. A nested container is restored when its host is:

- the app root or a ``TabRouter``; or
- a stack, split or modal restored in this launch that has not left its restored screens.

After the host changes (a push, a pop, a root change with `update(root:)`, a selection change in a split, a deeplink), the state saved under the old screens is stale and the nested containers start on their default state. It stays stale even if an equal screen is pushed again.

A host that was not restored because it is not `Codable`, or because nothing was saved for it, counts as restored on its default first-frame screens (its root screen, a split's sidebar) until its first change. The containers nested there are restored; after the first change they are treated as stale like everywhere else.

> Note: If the root of such a host was changed with `update(root:)` in the previous session, the state saved under the old root screen may be restored under the new default root. Make the host `Codable` to avoid it.

## Orphaned Saved State

A saved container that nothing asks for anymore, such as one under a renamed tab type or a removed tab case, is ignored without an error: the rest of the navigation is restored. Its bytes stay in the saved data until you call `clearNavigationRestoration()` or change the key.

## Clearing the Saved State at Logout

Call `clearNavigationRestoration()` on any ``RouterModel`` so the next launch does not reopen account screens:

```swift
func logout() {
    router.update(root: AppRoute.login)
    router.clearNavigationRestoration()
}
```

Clearing empties the saved state and erases the stored copy. It does not stop later saves: the next time the app leaves the foreground, the navigation at that moment is saved again. Navigate to the login screen first, then clear, so what is saved afterwards is the post-logout navigation. It does nothing when restoration is not enabled. `RouterSpy` records the call as `clearNavigationRestorationCallCount` (see <doc:Testing>).

## Security

> Warning: Saved routes are written to disk **in clear**, with no encryption. Never put a token, a password or any sensitive data in a `Codable` route. Pass an identifier and read the sensitive value from the keychain or your data layer, and clear the saved state at logout.

## Snapshot Size

The whole navigation of a window is stored as one JSON value in the scene storage, rewritten every time the scene leaves the foreground. Its size grows with the number of containers, the depth of the stacks and the size of each route's values, and the stack of a tab the user never visited is kept as it was saved. Keep routes small by passing identifiers rather than models or large collections, and clear the state at logout.

## Topics

### Related

- <doc:TabNavigation>
- <doc:SplitNavigation>
- <doc:Deeplinks>
- <doc:ConfigurationGuide>
- <doc:Troubleshooting>
- ``RouterError``
- ``RouterModel``
- ``SwiftUICore/View/navigationRestoration(_:)``
