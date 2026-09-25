# Split View Navigation in SwiftUI: Taming Sidebar Routing with RoutingSplitView

*Part 4 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270) and [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407). Part 3 covered tab navigation with `TabRouter` — this one covers the other kind of multi-column app: sidebar, content, and detail on iPad and Mac.*

Every Mail-like or Notes-like app on iPad and Mac faces the same three-column problem: a sidebar picks a folder, the folder picks a list of items, an item picks a detail view — and on iPhone, all three collapse into a single pushed stack. SwiftUI gives you `NavigationSplitView` to draw the columns. It gives you nothing to keep their selections in sync, coordinate them from outside the view that owns them, or handle the iPhone case without writing the same `if isCompact` branch in every screen that touches selection.

`RoutingSplitView` is `swift-routing`'s answer: one router, shared across all three columns, the same `push`/`present`/`cover` API you already know, plus typed selection bindings for content and detail.

---

## The Problem: NavigationSplitView's Selection State Is Yours to Manage

A typical 3-column setup starts innocently enough:

```swift
struct ContentView: View {
  @State private var selectedFolder: Folder?
  @State private var selectedNote: Note?

  var body: some View {
    NavigationSplitView {
      List(folders, selection: $selectedFolder) { folder in
        Text(folder.name).tag(folder)
      }
    } content: {
      if let selectedFolder {
        List(selectedFolder.notes, selection: $selectedNote) { note in
          Text(note.title).tag(note)
        }
      }
    } detail: {
      if let selectedNote {
        NoteDetailView(note: selectedNote)
      }
    }
  }
}
```

It works, until something *outside* this view needs to drive a selection — a push notification that should open a specific note, a "View in Notes" button from a share sheet, a deep link. None of that state is reachable from anywhere else; it's private `@State` sitting in whichever view happens to own the `NavigationSplitView`. You end up threading bindings down, or reaching for a shared `@Observable` model that exists purely to route around SwiftUI's own state ownership rules.

Then there's iPhone. `NavigationSplitView` collapses to a single column there, and the auto-selection that makes sense on iPad — select the first folder, then its first note, so the detail column isn't empty — actively fights the user on iPhone, since it pushes them straight past the folder list they were about to tap through themselves.

---

## RoutingSplitView: One Router, Three Columns

`RoutingSplitView` gives sidebar, content, and detail a single shared, split-type `Router`, injected into the environment the same way as everywhere else in swift-routing:

```swift
@Environment(\.router) var router
```

**2-column** (sidebar + detail):

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (folder: Folder) in
  AppRoute.notes(folder)
}
```

**3-column** (sidebar + content + detail) — add a `detail:` closure and the middle column appears, driven by whatever the content closure returns:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (folder: Folder) in
  AppRoute.notes(folder)
} detail: { (note: Note) in
  AppRoute.note(note)
}
```

Same router, same environment key, in both cases — the number of trailing closures you provide is what decides the layout, not a different type you have to learn.

---

## Driving Selections

`router.detailBinding(as:)` and `router.contentBinding(as:)` wire a `List` selection directly, exactly like SwiftUI's own `selection:` parameter — because that's what they are under the hood:

```swift
struct SidebarScreen: View {
  @Environment(\.router) var router
  let folders: [Folder] = Folder.all

  var body: some View {
    List(folders, selection: router.detailBinding(as: Folder.self)) { folder in
      NavigationLink(folder.name, value: folder)
    }
    .onFirstAppear {
      guard !router.isCompact else { return }
      router.select(detail: folders.first)
    }
  }
}
```

Tapping a row and calling `router.select(detail:)` programmatically go through the exact same path — a selection made by a tap logs the same `.navigation` event a manual call would, so there's nothing separate to test or reason about.

When a screen needs to work for *either* layout, `router.hasContentColumn` tells you which column you're actually driving:

```swift
if router.hasContentColumn {
  router.select(content: folder)
} else {
  router.select(detail: folder)
}
```

This is the same branch `SidebarScreen` needs in a real 2-vs-3-column app: in 3-column mode the sidebar's selection lands in the *content* column (the folder's note list); in 2-column mode there's no content column, so the sidebar's selection lands directly in *detail*.

---

## Compact Mode: Don't Auto-Select on iPhone

That `guard !router.isCompact else { return }` above isn't defensive boilerplate — it's the whole reason compact mode doesn't feel broken. `NavigationSplitView` collapses to one column on iPhone, and `router.isCompact` reflects `horizontalSizeClass` (it updates live during iPad multitasking too, not just at launch). Skip the guard, and the same auto-select-first-item logic that makes an iPad app open straight to something useful will, on iPhone, yank the user two screens deep before they've tapped anything.

One property, checked once, and both platforms get the behavior that's actually right for them — no `#if os(iOS)` branching on idiom, no separate iPhone code path to maintain.

---

## Navigating and Presenting From Any Column

Since sidebar, content, and detail all share the *same* router, `router.push(_:)` always pushes onto the one navigation stack that exists — and that stack only ever renders in the detail column. Push from the sidebar's own code, and it still shows up in detail, not as a new sidebar screen.

`router.present(_:)` and `router.cover(_:)` work the same way, router-wide rather than per-column: call either from any of the three columns and you get one sheet or cover over the whole split view, not three independent presentation layers to keep untangled.

---

## Deep Linking Into Specific Columns

`SplitDeeplinkHandler` mirrors the plain `DeeplinkHandler` from earlier in this series, but returns a `SplitDeeplink<ContentData, DetailData, R>` instead of a bare route — a content selection, a detail selection, and an optional route to push once both are set:

```swift
struct NoteSplitDeeplinkHandler: SplitDeeplinkHandler {
  func deeplink(from route: DeeplinkIdentifier) async throws -> SplitDeeplink<Folder, Note, AppRoute>? {
    switch route {
    case let .note(note):
      SplitDeeplink(content: note.folder, detail: note)
    default:
      nil
    }
  }
}
```

`router.handle(splitDeeplink:)` applies it in a fixed order — select `content` (3-column layout only; a no-op if this router has no content column), then select `detail`, then apply the optional `deeplink` within the detail column's own navigation stack:

```swift
router.handle(splitDeeplink: splitDeeplink)
```

The content column never has a navigation stack of its own — only detail does — so that trailing `deeplink`, if present, can only ever push further *within* detail, regardless of which column's selection led there.

---

## Before and After

A concrete trigger: a push notification arrives for a specific note. Tapping it should open the app on the right folder *and* the right note, in whichever column layout is currently showing.

**Before — three pieces of state, and a compact-mode branch to get right by hand:**

```swift
final class NotificationRouter: ObservableObject {
  @Published var pendingFolder: Folder?
  @Published var pendingNote: Note?
}

// Somewhere near the root
func didTapNoteNotification(note: Note) {
  notificationRouter.pendingFolder = note.folder
  notificationRouter.pendingNote = note
}

// Inside the view that owns selectedFolder/selectedNote
.onChange(of: notificationRouter.pendingNote) { _, note in
  guard let note else { return }
  selectedFolder = note.folder
  selectedNote = horizontalSizeClass == .compact ? nil : note
  // ...and now decide, by hand, how to push onto whatever stack
  // is currently visible in compact mode, separately from this.
}
```

**After — one call, layout-agnostic:**

```swift
func didTapNoteNotification(note: Note) {
  router.handle(splitDeeplink: SplitDeeplink(content: note.folder, detail: note))
}
```

`select(content:)` already no-ops safely if the router has no content column, so the exact same call works whether the app is currently showing 2 or 3 columns — no `horizontalSizeClass` check, no separate compact-mode branch to keep in sync with the one in `SidebarScreen`.

---

## Why This Matters

Sidebar/content/detail navigation is the default shape for any serious iPad or Mac app, and it's noticeably less covered than tab-based navigation — most SwiftUI navigation writing stops at `NavigationStack`. The gap isn't whether `NavigationSplitView` *can* do this; it's that keeping three columns' selections coherent, reachable from outside the view that draws them, and correct in compact mode, is left entirely to you.

`RoutingSplitView` closes that gap the same way the rest of swift-routing does: one router, typed selections instead of loose `@State`, and a `SplitDeeplinkHandler` that makes "open the app on exactly this content and detail" a single, testable call — on iPad, on Mac, and on iPhone once it collapses.

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
