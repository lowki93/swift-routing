# Navigation Restoration

Use this guide to bring users back to the same screens after the system kills the app in the background.

## Enable

Apply `.navigationRestoration()` once per scene, at the root, **before** `.environment(\.router, ...)`. Inside a `RoutingView`, split or modal it is a silent no-op; never apply it around the `RoutingView`s of a `RoutingTabView` (the environment router is still the root there, a second store would be attached). Without it nothing is saved, checked or logged.

```swift
RoutingView(destination: HomeRoute.self, root: .home)
  .navigationRestoration()
  .environment(\.router, router)
```

- Inject one root `Router` per window; never rely on the shared default router.
- An optional key names the saved state; changing it starts fresh.

## Codable rule

A container is restored only when its types are `Codable`: routes (with associated values and nested routes), the tab type of a `TabRouter`, and the route type, `ContentData` and `DetailData` of a `RoutingSplitView` (`Never` is `Codable`).
- Pass stable identifiers in routes (`profile(userID:)`), not models.
- Keep route `name`s and tab type names stable: they are the container identity in the saved state.
- A plain `TabView` (no `TabRouter`) does not restore its selected tab.

## Lifetime

- Saved when the scene leaves `.active`; restored after a system kill; discarded when the user closes the app from the app switcher; one state per window.
- A deeplink at launch is applied on top of the restored state.

## Failures

Logged once per container as `.error(.restoration(reason))`; the container starts on its default state (on `decodingFailed` its subtree too), others are restored. Reasons: `notCodable`, `decodingFailed`, `encodingFailed`, `duplicateKey`.
- `shouldCrashOnRouteNotFound` crashes only on `notCodable` (when restoration is on), never on decoding failures.
- `RouterError.restoration` is a new case: exhaustive `switch` over `RouterError` must handle it.

## Nested containers

A container built inside a screen is restored only under the app root, a tab router, or a host restored in this launch that has not left its restored screens (a pop below them, root change, selection change, deeplink; a push or pop on a host that started on its default screens also counts). A non-`Codable` host or one with nothing saved counts as restored on its default screens until its first change. Limit: after `update(root:)` in the previous session, the nested state of the old root screen may be seeded under the default root.

## Logout and security

- Navigate to the login screen, then call `router.clearNavigationRestoration()`; later saves are not blocked.
- Saved routes are stored on disk in clear: no token or sensitive data in a route.
- The whole navigation is one JSON value rewritten on each background; keep routes small.
