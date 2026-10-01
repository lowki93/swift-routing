# Migrating an Existing SwiftUI App to swift-routing, One Screen at a Time

*Part 6 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270) and [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407). Parts 3, 4, and 5 covered tab navigation, split views, and testing — this one is about getting swift-routing into an app that already exists, without a rewrite.*

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

## A Quick Note on Deep Links

TaskFlow also has a hand-rolled `.onOpenURL` that parses `taskflow://task/<id>` and mutates `path` directly — the same kind of code `router.push`/`present`/`cover` replaced above, just triggered from a URL instead of a button. Migrating it follows the same shape, through `DeeplinkHandler` and `DeeplinkRoute` instead of manual `NavigationPath` surgery — but it deserves its own full treatment rather than a rushed paragraph here. The short version for a migration in progress: deep links don't need to move on day one. They can keep working exactly as they are until every screen they target has already moved to `Route`/`router`.

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
| Hand-rolled `.onOpenURL` + path mutation | `DeeplinkHandler` / `DeeplinkRoute` — own article |

---

## Why This Matters

A migration that requires a flag day — rewrite every screen before anything ships — is a migration most teams never start. swift-routing doesn't ask for one: the type system doesn't care that half your screens still use `NavigationStack` directly, and nothing about `RoutingView` requires it to own the whole app at once. Each flow you move gets type-safe routes and a testable router; everything you haven't touched yet keeps working exactly as it did yesterday, and nobody reviewing the diff for the Settings flow needs to also review a rewritten Dashboard to feel safe merging it.

That's the actual test for whether a navigation library is adoptable in a real codebase, not just a green-field one: can you stop halfway through and still have something that compiles, ships, and makes sense. TaskFlow can stop after migrating just Settings and be strictly better off than before — no half-finished abstraction, no screens left in a broken in-between state.

*Migrating hand-rolled deep links to `DeeplinkHandler`, and what Swift 6's strict concurrency changes about all of this, are their own topics — coming up later in this series.*

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
