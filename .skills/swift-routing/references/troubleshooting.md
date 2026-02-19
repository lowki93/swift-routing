# Troubleshooting

Use this guide to quickly diagnose common SwiftRouting issues.

## onAppear / onDisappear Called Multiple Times

**Symptom**
- A route logs multiple `appear/disappear` events.
- Most visible in tab flows or when updating roots.

**Why it happens**
- SwiftUI may preload tab content.
- Root updates can recreate route views.

**What to do**
- Make side effects idempotent.
- Prefer `task(id:)` for data loading.
- Avoid relying on a single `onAppear` call for critical one-time logic.

## `@Environment(\.tabRouter)` Is Nil

**Symptom**
- `tabRouter` is unavailable where deeplink or navigation code runs.

**Why it happens**
- `tabRouter` is injected inside `RoutingTabView` descendants only.

**What to do**
- In parent containers, use `@Environment(\.router)` and access `router.tabRouter`.
- Keep tab-specific actions inside `RoutingTabView` scope when possible.

## `NavigationLink(route:)` Does Not Present Sheet/Cover

**Symptom**
- Route with modal intent still performs push.

**Why it happens**
- `NavigationLink(route:)` is push-only stack navigation.

**What to do**
- Use `router.present(...)` or `router.cover(...)` for modal flows.
- Use `NavigationLink(route:)` for user-driven push navigation.

## Sheet Modifiers Not Applied (`presentationDetents`, `presentationDragIndicator`)

**Symptom**
- Sheet customizations appear ignored or inconsistent.

**Why it happens**
- Presentation with stack wrapping can affect where modifiers apply.

**What to do**
- Use `router.present(route, withStack: false)` when direct sheet modifiers are required.
- Or set `routingType` to `.sheet(withStack: false)` for that route.

## Route Not Found (Error UI or Crash)

**Symptom**
- You see a "route not defined" error view, or app crashes on missing route.

**Why it happens**
- Route type does not match the `RouteDestination` mapping in the active `RoutingView`.
- `shouldCrashOnRouteNotFound` decides whether it crashes.

**What to do**
- Verify `RoutingView(destination: ...)` matches the route type you navigate to.
- In development/CI, prefer `shouldCrashOnRouteNotFound: true`.
- In production, prefer `false` to avoid user-facing crashes.

## `terminate(_:)` Behavior Is Not What You Expected

**Symptom**
- You expected a specific back target, but got `close()` or a single `back()`.

**Why it happens**
- `terminate(_:)` executes observers, then navigation completion depends on current router state:
  1. pop to local context anchor if found,
  2. else close if presented,
  3. else back one level.

**What to do**
- Treat `terminate(_:)` as flow completion, not always "go back to exact observer route".
- Use explicit navigation when exact return behavior is required.

## Deeplink Resolves But Navigation Does Not Happen

**Symptom**
- Deeplink parsing works, but no route is shown.

**Why it happens**
- Handler returns `nil`.
- Handler route type does not match active `RoutingView(destination:)`.
- Wrong router scope is used (`router` vs `router.tabRouter`).

**What to do**
- Add logs around parsed identifier and handler result.
- Validate `DeeplinkHandler.D` matches destination route type.
- For tab deeplinks in parent scope, use `router.tabRouter?.handle(...)`.

## Context Observer Leaks or Duplicate Triggers

**Symptom**
- Observers keep firing after screen lifecycle changes.
- Memory growth due to retained references.

**Why it happens**
- Strong captures in context closures.
- Manual `add(context:)` without proper `remove(context:)`.

**What to do**
- Use weak captures for class references (`[weak self]`, `[weak viewModel]`).
- In views, prefer `.routerContext(...)`.
- In manual patterns, pair `add(context:)` with cleanup (`remove(context:)`).

## Tab Action Runs In Unexpected Tab

**Symptom**
- Action appears to execute in a different tab than expected.

**Why it happens**
- `update/push/present/cover` with non-`nil` tab auto-switches tab first.

**What to do**
- Pass explicit tab when you want cross-tab navigation.
- Pass `in: nil` when you want current-tab behavior.
- Log `change(tab:)` actions during debugging to confirm flow.
