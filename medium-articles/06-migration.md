# Migrating an Existing SwiftUI App to swift-routing, One Screen at a Time

*Part 6 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270), [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407), [Part 3: Tab Navigation in SwiftUI: Taming Cross-Tab Routing with TabRouter](https://medium.com/@budainkevin/tab-navigation-in-swiftui-taming-cross-tab-routing-with-tabrouter-dc7b4f595b45), [Part 4: SplitView Navigation in SwiftUI: Taming Sidebar Routing with RoutingSplitView](https://medium.com/@budainkevin/splitview-navigation-in-swiftui-taming-sidebar-routing-with-routingsplitview-b19cf97bfa9b), and [Part 5: Testing SwiftUI Navigation Without Mounting a Single View](https://medium.com/@budainkevin/testing-swiftui-navigation-without-mounting-a-single-view-43e8ef870716). This one is about getting swift-routing into an app that already exists, without a rewrite.*

Every article in this series so far has shown swift-routing starting from an empty project. Almost no real app gets that luxury. The actual question most developers have isn't "is this better than `NavigationStack`" — it's "can I adopt this gradually, on a codebase that already ships, without a flag day where everything breaks at once." The answer is yes, screen by screen, and this article walks through exactly how, using a small task-tracking app — TaskFlow — as the running example.

---

## Starting Point: TaskFlow, Four Screens, Zero swift-routing

TaskFlow has a task list, a detail screen reached by tapping a row, a settings sheet, and a one-time onboarding cover — all wired by hand:

```swift
struct TaskListView: View {
  @State private var path: [Task] = []
  @State private var showSettings = false
  @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarded")

  var body: some View {
    NavigationStack(path: $path) {
      List(tasks) { task in
        NavigationLink(value: task) { Text(task.title) }
      }
      .navigationDestination(for: Task.self) { task in
        TaskDetailView(task: task)
      }
      .toolbar {
        Button("Settings") { showSettings = true }
      }
    }
    .sheet(isPresented: $showSettings) { SettingsView() }
    .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }
    .onOpenURL { url in
      guard url.pathComponents.count > 2, url.pathComponents[1] == "task",
            let task = tasks.first(where: { $0.id.uuidString == url.pathComponents[2] })
      else { return }
      path = [task]
    }
  }
}
```

Nothing unusual — this is how most SwiftUI apps still look, deep link included: a `.onOpenURL` closure parsing path components by hand and reaching into `path` directly. That's the point of walking through TaskFlow rather than a toy example: swift-routing doesn't need you to start over, it needs you to start somewhere.

---

## Step 1: Add Routes Without Changing Behavior

Before touching a single call site, define what TaskFlow's screens are as a `Route`:

```swift
enum TaskRoute: Route {
  case list
  case detail(Task)
  case settings
  case onboarding

  var name: String {
    switch self {
    case .list: "list"
    case .detail(let task): "detail(\(task.id))"
    case .settings: "settings"
    case .onboarding: "onboarding"
    }
  }

  var routingType: RoutingType {
    switch self {
    case .settings: .sheet()
    case .onboarding: .cover
    default: .push
    }
  }
}

extension TaskRoute: RouteDestination {
  static func view(for route: TaskRoute) -> some View {
    switch route {
    case .list: TaskListView()
    case .detail(let task): TaskDetailView(task: task)
    case .settings: SettingsView()
    case .onboarding: OnboardingView()
    }
  }
}
```

This compiles alongside the existing `NavigationStack` code and changes nothing at runtime — it's pure addition, safe to commit on its own.

---

## Step 2: Swap NavigationStack for RoutingView

The `path: [Task]` and `.navigationDestination(for:)` go away entirely — `RoutingView` and `TaskRoute`'s own `RouteDestination` conformance already cover that dispatch:

```swift
struct TaskFlowRoot: View {
  var body: some View {
    RoutingView(destination: TaskRoute.self, root: .list)
  }
}
```

For most single-stack screens, this is the whole migration. The screen's own body barely changes; what disappears is the bookkeeping around it.

---

## Step 3: Migrate Push, Sheet, and Cover Call Sites

Each native trigger has a direct swift-routing equivalent:

```swift
// Before
NavigationLink(value: task) { Text(task.title) }
Button("Settings") { showSettings = true }

// After
NavigationLink(route: TaskRoute.detail(task)) { Text(task.title) }
Button("Settings") { router.present(TaskRoute.settings) }
```

Onboarding needs no `@State` flag or `.fullScreenCover(isPresented:)` pair at all — `router.cover(TaskRoute.onboarding)` is enough, because `routingType` already told the route which presentation style to use. Both booleans, and the modifiers reading them, are gone.

Two details are worth knowing before you search-and-replace your way through a codebase:

- `NavigationLink(route:)` is **push only**. If a row used to open a sheet, it becomes a `Button` calling `router.present(_:)`, not a `NavigationLink`.
- If the sheet relied on presentation modifiers like `presentationDetents`, present it without the navigation stack that `.sheet()` wraps it in by default, so the modifiers apply to your content directly:

```swift
// On the route
case .settings: .sheet(withStack: false)

// Or at the call site
router.present(TaskRoute.settings, withStack: false)
```

---

## Step 4: Replace dismiss() Inside the Migrated Flow

Inside a migrated flow, `@Environment(\.dismiss)` has a direct replacement:

```swift
// Before
@Environment(\.dismiss) private var dismiss
Button("Close") { dismiss() }

// After
@Environment(\.router) private var router
Button("Close") { router.close() }
```

`router.close()` dismisses the current presented modal and is a no-op if the router isn't presented, so it's safe to call from a screen that can be reached both ways. This only applies once the screen lives inside a `RoutingView` — which is exactly what the next section is about.

---

## Step 5: Replace Callbacks and Bindings With a RouteContext

Hand-wired apps usually pass data back up through closures or `@Binding`s threaded through initializers. In TaskFlow, say `SettingsView` takes an `onSortChange: (SortOrder) -> Void` closure so the task list can re-sort when the user picks a new order. That wiring is exactly what [Part 2](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407) replaced:

```swift
struct SortOrderContext: RouteContext {
  let order: SortOrder
}

// TaskListView: observe it
.routerContext(SortOrderContext.self) { context in
  sortOrder = context.order
}

// SettingsView: send it and dismiss in one call
router.terminate(SortOrderContext(order: .dueDate))
```

`SettingsView` no longer needs to know who presented it, and `TaskListView` no longer needs to hand it a closure. This step is optional for a first pass — a closure that works can stay a closure — but it's where most of the real simplification lives once the basic routes are in.

---

## The Pitfall: Where You Put RoutingView Decides What router Means

`@Environment(\.router)` only resolves to a real swift-routing router for views mounted *inside* a `RoutingView`'s subtree. If you wrap only the task list and its detail screen in a `RoutingView`, but that flow is itself presented natively from a screen that hasn't migrated yet:

```swift
struct DashboardView: View {
  @State private var showTasks = false

  var body: some View {
    Button("Tasks") { showTasks = true }
      .sheet(isPresented: $showTasks) {
        TasksFeatureRoutingView()   // wraps RoutingView(destination: TaskRoute.self, root: .list)
      }
  }
}
```

...then `DashboardView` itself has no router to call. That's correct, not a bug: `DashboardView` is still plain SwiftUI, so it keeps using `$showTasks` and `@Environment(\.dismiss)` — `router.close()` only makes sense for code already inside the migrated subtree. The dividing line is the `RoutingView` boundary, not the screen boundary. Decide where that line sits on purpose, feature by feature, rather than finding it by surprise when a button doesn't see the router you expected.

---

## Migrate One Flow at a Time

That boundary is also the migration strategy: native `NavigationStack` code and `RoutingView` code can coexist indefinitely in the same app. Pick one self-contained flow — Settings and Onboarding are usually the easiest, since neither shares navigation state with the rest of the app — wrap just that flow in its own `RoutingView`, and keep presenting it from the unmigrated rest of the app exactly as before:

```swift
struct TasksFeatureRoutingView: View {
  var body: some View {
    RoutingView(destination: TaskRoute.self, root: .list)
  }
}
```

From `DashboardView`'s side, `TasksFeatureRoutingView()` is just another view handed to `.sheet(isPresented:)` — it has no idea, and no need to know, that everything inside it now runs on routes and a router. Ship that one flow, confirm it behaves, then move to the next. The outermost `NavigationStack` — usually the app's root tab or window — is the last thing to migrate, not the first; by the time you get to it, every call site it used to own has already been proven out in isolation.

---

## What About Tabs?

If TaskFlow grows a `TabView` — say Tasks, Search, and Profile — the migration has two options, depending on whether you need to drive tabs from code.

**Option 1: `RoutingTabView`** (recommended when a screen in one tab needs to push into another):

```swift
enum AppTab: TabRoute {
  case tasks, search, profile

  var name: String {
    switch self {
    case .tasks: "tasks"
    case .search: "search"
    case .profile: "profile"
    }
  }
}

struct ContentView: View {
  @State private var selectedTab: AppTab = .tasks

  var body: some View {
    RoutingTabView(tab: $selectedTab, destination: TaskRoute.self) { destination in
      RoutingView(tab: .tasks, destination: destination, root: .list)
        .tabItem { Label("Tasks", systemImage: "checklist") }

      RoutingView(tab: .search, destination: destination, root: .search)
        .tabItem { Label("Search", systemImage: "magnifyingglass") }

      RoutingView(tab: .profile, destination: destination, root: .profile)
        .tabItem { Label("Profile", systemImage: "person") }
    }
  }
}
```

This is what unlocks `@Environment(\.tabRouter)` and calls like `tabRouter?.push(TaskRoute.detail(task), in: .tasks)` from anywhere — the subject of [Part 3](https://medium.com/@budainkevin/tab-navigation-in-swiftui-taming-cross-tab-routing-with-tabrouter-dc7b4f595b45).

**Option 2: keep the native `TabView`** and only give each tab its own `RoutingView`, with `.tabToRoot` so tapping the already-selected tab pops back to its root:

```swift
TabView(selection: .tabToRoot(for: $selectedTab, in: router)) {
  RoutingView(tab: .tasks, destination: TaskRoute.self, root: .list)
    .tabItem { Label("Tasks", systemImage: "checklist") }
  // ...
}
```

It's the smaller change, and perfectly fine if tabs never need to talk to each other — with one catch: this option does **not** provide `@Environment(\.tabRouter)`. Start here if you want a minimal first step, and move to `RoutingTabView` the day a cross-tab push shows up in a ticket.

---

## Migrating the Deep Link

TaskFlow also has a hand-rolled `.onOpenURL` that parses `taskflow://task/<id>` and mutates `path` directly — the same kind of code `router.push`/`present`/`cover` replaced above, just triggered from a URL instead of a button. The replacement splits that closure into two small, separately testable pieces.

First, a typed identifier that owns the URL parsing and nothing else:

```swift
enum TaskDeeplinkIdentifier: Hashable, Sendable {
  case task(id: UUID)

  init?(url: URL) {
    guard url.pathComponents.count > 2, url.pathComponents[1] == "task",
          let id = UUID(uuidString: url.pathComponents[2])
    else { return nil }
    self = .task(id: id)
  }
}
```

Then a `DeeplinkHandler` that maps the identifier to a route:

```swift
struct TaskDeeplinkHandler: DeeplinkHandler {
  typealias R = TaskDeeplinkIdentifier
  typealias D = TaskRoute

  let tasks: [Task]

  func deeplink(from route: TaskDeeplinkIdentifier) async throws -> DeeplinkRoute<TaskRoute>? {
    switch route {
    case .task(let id):
      guard let task = tasks.first(where: { $0.id == id }) else { return nil }
      return .push(.detail(task))
    }
  }
}
```

And `.onOpenURL` shrinks to glue:

```swift
.onOpenURL { url in
  Task {
    guard let identifier = TaskDeeplinkIdentifier(url: url),
          let deeplink = try? await handler.deeplink(from: identifier)
    else { return }
    router.handle(deeplink: deeplink)
  }
}
```

Three things got better at once: URL parsing is a plain `init?(url:)` you can unit-test with string literals, the "which screen does this open" decision is a pure function from identifier to route, and the async hook means a link to a task that isn't loaded yet can fetch it before returning, instead of silently doing nothing. Path building and tab-aware links go further than this — the [Deeplinks guide](https://lowki93.github.io/swift-routing/documentation/swiftrouting/deeplinks) covers them.

The timing advice still holds, though: deep links don't need to move on day one. The old closure can keep working exactly as it is until every screen it targets has already moved to `Route`/`router`. Migrate it last among the flows, not first.

---

## Prove It With a Test

A migrated flow earns something the native version never had: its navigation decisions can be tested without mounting a view. Move the "where does this go" line into a model that takes `any RouterModel`, and the check becomes a few lines with `RouterSpy`, exactly as in [Part 5](https://medium.com/@budainkevin/testing-swiftui-navigation-without-mounting-a-single-view-43e8ef870716):

```swift
@Test @MainActor
func openSettings_presentsSettingsRoute() {
  let spy = RouterSpy(root: TaskRoute.list)
  let model = TaskListModel(router: spy)

  model.openSettings()

  #expect((spy.presentedRoutes.first as? TaskRoute) == .settings)
}
```

A useful habit while migrating: write this test the moment a flow lands on routes. It pins the behavior you just preserved, and it makes the next flow's migration safer, because you've already shown the pattern works in this codebase.

---

## Common Gotchas

- **Calling `router` from an unmigrated screen.** It doesn't resolve there — see the boundary section above. The fix is to keep using native SwiftUI in that screen, not to wrap it in a `RoutingView` just to get a router.
- **Putting a `RoutingView` inside another one by accident.** Each `RoutingView` owns its own stack. Nest them only where a flow is genuinely presented as a separate unit, like a sheet or a tab.
- **Reusing one route enum for everything.** A single `TaskRoute` is fine for TaskFlow. In a bigger app, one enum per feature keeps routes small and lets features migrate independently.
- **Deleting the old `@State` before the new call site works.** Migrate a screen's triggers and its state in the same commit, but run the app between screens, not at the end.

---

## Before and After, Checklist Form

| Native SwiftUI | swift-routing |
|---|---|
| `NavigationStack(path:)` | `RoutingView(destination:root:)` |
| `.navigationDestination(for:)` | `RouteDestination.view(for:)` |
| `NavigationLink(value:)` | `NavigationLink(route:)` |
| `.sheet(isPresented:)` + `@State` flag | `router.present(_:)` |
| `.fullScreenCover(isPresented:)` + `@State` flag | `router.cover(_:)` |
| `@Environment(\.dismiss)` (inside a migrated flow) | `router.close()` |
| `.sheet` needing `presentationDetents` | `router.present(_:withStack: false)` |
| Closures / `@Binding` passed back up | `RouteContext` + `router.terminate(_:)` |
| `TabView(selection:)` | `RoutingTabView` (or `TabView` + `.tabToRoot`) |
| Hand-rolled `.onOpenURL` + path mutation | `DeeplinkHandler` / `DeeplinkRoute` |

---

## Why This Matters

A migration that requires a flag day — rewrite every screen before anything ships — is a migration most teams never start. swift-routing doesn't ask for one: the type system doesn't care that half your screens still use `NavigationStack` directly, and nothing about `RoutingView` requires it to own the whole app at once. Each flow you move gets type-safe routes and a testable router; everything you haven't touched yet keeps working exactly as it did yesterday, and nobody reviewing the diff for the Settings flow needs to also review a rewritten Dashboard to feel safe merging it.

That's the actual test for whether a navigation library is adoptable in a real codebase, not just a green-field one: can you stop halfway through and still have something that compiles, ships, and makes sense. TaskFlow can stop after migrating just Settings and be strictly better off than before — no half-finished abstraction, no screens left in a broken in-between state.

*Swift 6's strict concurrency and what it changes about all of this is its own topic — coming up later in this series.*

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
