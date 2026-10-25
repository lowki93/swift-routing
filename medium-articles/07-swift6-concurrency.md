# Swift 6 Strict Concurrency, One Navigation Layer Later

*Part 7 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270), [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407), [Part 3: Tab Navigation in SwiftUI: Taming Cross-Tab Routing with TabRouter](https://medium.com/@budainkevin/tab-navigation-in-swiftui-taming-cross-tab-routing-with-tabrouter-dc7b4f595b45), [Part 4: SplitView Navigation in SwiftUI: Taming Sidebar Routing with RoutingSplitView](https://medium.com/@budainkevin/splitview-navigation-in-swiftui-taming-sidebar-routing-with-routingsplitview-b19cf97bfa9b), and [Part 5: Testing SwiftUI Navigation Without Mounting a Single View](https://medium.com/@budainkevin/testing-swiftui-navigation-without-mounting-a-single-view-43e8ef870716). Part 6 covered migrating an existing app — this one is about what happens when that app also flips on Swift 6.*

<!-- TODO: add the Part 6 (migration) link once it is published -->

Most Swift 6 migration write-ups I've read are about the concurrency model in general: actors, `Sendable`, the data-race safety story. Very few are about what strict concurrency does to one specific layer of an app, and navigation is a layer where it bites in unusual ways — it's UI-bound, it's driven by values that travel between screens, and it's triggered from places that are *not* UI (a deep link arriving from a URL, an async fetch that decides where to go).

The migration I lived through took somewhere between six and nine months. Swift 6 wasn't the only reason — it ran in parallel with a move to Domain-Driven Design, which meant the code was being reorganized under our feet while the compiler was getting stricter about it.

<!-- SORARE: 2-3 sentences of personal context here. What was the most painful part: Swift 6 or the DDD move? Where did navigation get stuck between the two? Keep it concrete, no invented numbers. -->

This article is the navigation-specific part of that story: what the compiler actually said, what it meant, and how swift-routing's API is shaped around it. Everything below was compiled with Swift 6.4 in Swift 6 language mode — error wording drifts between releases, so yours may read slightly differently.

---

## First, What "Swift 6" Means for This Package

`Package.swift` declares `// swift-tools-version: 6.0`, and there is no `swiftLanguageMode` override anywhere. With a 6.0 tools version, the default language mode is Swift 6 — strict concurrency checking is on, and violations are errors, not warnings.

A navigation library sits at the seam between UI code and everything else in your app, so one that only compiled cleanly in Swift 5 mode would push its warnings into every consumer. If your app is in Swift 6 mode, swift-routing is built in that same mode.

---

## Pitfall 1: Your Routes Have to Be Sendable

The protocol is declared as:

```swift
public protocol Route: Hashable, Sendable, CustomStringConvertible
```

`Hashable` was always a given for anything used as a `NavigationStack` path element. `Sendable` is the new constraint, and it hits the moment a route carries an associated value that isn't safe to pass across isolation boundaries:

```swift
final class LegacyService {}

enum MyRoute: Route {
  case home
  case profile(LegacyService)
}
```

The compiler's first message is the one that matters:

```
error: associated value 'profile' of 'Sendable'-conforming enum 'MyRoute'
       has non-Sendable type 'LegacyService'
note:  class 'LegacyService' does not conform to the 'Sendable' protocol
```

It is followed by a small avalanche — `MyRoute` also fails `Hashable` and `Equatable`, because `LegacyService` is neither. Read the *first* error and ignore the cascade; fixing the first usually makes the rest disappear.

The fix is almost always a design fix, not a keyword fix. A route shouldn't carry a live service object — it should carry *what you need to find it*:

```swift
enum MyRoute: Route {
  case home
  case profile(userId: String)   // a value, not a reference
}
```

Not by coincidence, this is also what makes a route usable in a deep link, in analytics, and in a test (Part 5). The compiler pushed us toward the shape we should have had anyway.

---

## Pitfall 2: RouteContext Is Sendable by Construction

Part 2 introduced `RouteContext` as the way a child screen hands data back to its parent. Its definition is a one-liner:

```swift
public typealias RouteContext = Hashable & Sendable
```

There is no class to subclass and no protocol with requirements — a context is any type that is both `Hashable` and `Sendable`. The practical consequence is the same as for routes: a context built from value types just works, and one that smuggles in a reference type doesn't compile.

```swift
final class User: Hashable { /* … */ }

struct UserSelectionContext: RouteContext {
  let user: User
}
```

```
error: stored property 'user' of 'Sendable'-conforming struct
       'UserSelectionContext' has non-Sendable type 'User'
```

If your domain model is made of classes, the lesson is the same: send an identifier or a `Sendable` value-type snapshot through the context, and let the receiving screen resolve it. That also keeps contexts honest about what actually crosses the child→parent boundary.

<!-- SORARE: one real example of a context/route that had to change during the migration, if you have one. -->

---

## Pitfall 3: The Router Isn't a `@MainActor` Type

It's easy to summarize this as "`Router` and `TabRouter` are `@MainActor`", and that isn't what the code does, so it's worth being precise:

```swift
public final class Router: BaseRouter, @unchecked Sendable
public final class TabRouter: BaseRouter, @unchecked Sendable
```

Neither class is annotated `@MainActor`. Instead, the methods that mutate navigation state are annotated individually:

```swift
@MainActor func handle(deeplink: DeeplinkRoute<some Route>)
@MainActor public func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void)
```

And the protocols those classes adopt are deliberately *not* isolated — the conformances are written `@preconcurrency`:

```swift
extension Router: @preconcurrency RouterModel { … }
```

Why does that matter to you? Because of what it lets other conformers do. `RouterSpy`, the test double from Part 5, implements the protocol with plain non-isolated methods:

```swift
public final class RouterSpy: ObservableObject, RouterModel, @unchecked Sendable {
  public func push(_ destination: some Route) { … }
}
```

If `RouterModel` were `@MainActor` all the way down, every ViewModel taking an `any RouterModel` would be forced onto the main actor, and every test would need `@MainActor` just to hold a spy. The only isolated requirement in that whole family is `deepestRouter()`, and `RouterSpy` marks that single method `@MainActor` to match.

So: *the real router's mutating API is main-actor-isolated; the protocol it's reached through is not.* Keep that sentence in your head — it explains most of the errors in the next section.

---

## Pitfall 4: Reading the Errors When You Call the Router From the Wrong Place

Because the router's mutating methods are `@MainActor`, calling them from code that isn't on the main actor is a compile error. Two shapes of it come up constantly.

**From a synchronous, non-isolated function:**

```swift
final class Coordinator {
  let router = FakeRouter()      // stand-in with @MainActor methods

  func sync() {
    router.handle()
  }
}
```

```
error: call to main actor-isolated instance method 'handle()' in a
       synchronous nonisolated context
```

**From a detached task:**

```swift
func openURL() {
  Task.detached {
    self.router.handle()
  }
}
```

```
error: main actor-isolated instance method 'handle()' cannot be called
       from outside of the actor
```

Both mean the same thing: you're not on the main actor, and the method you're calling insists on it. The fixes are the boring, correct ones — make the calling function `@MainActor`, or hop explicitly with `Task { @MainActor in … }` / `await MainActor.run { … }`.

One honest note, because I got it backwards when drafting this article: I expected a bare `Task { router.handle() }` inside SwiftUI's `.onOpenURL` to fail too. On Swift 6.4 it *doesn't* — the `onOpenURL` closure inherits the view's main-actor isolation, and a plain `Task { }` inherits it in turn. That's easy to forget when you move the same code into a coordinator or a ViewModel that is *not* main-actor-isolated, where the very same `Task { }` suddenly does fail. If a snippet compiles in a View and breaks when you extract it, isolation inheritance is the first thing to check.

<!-- SORARE: paste 2-3 real compiler errors from the migration (copy-paste the exact text), what caused each, and how you fixed it. This is the section readers will screenshot. -->

---

## Pitfall 5: A Deep Link Handler Is `async throws` — So Where Does It Run?

```swift
public protocol DeeplinkHandler {
  associatedtype R: Hashable & Sendable
  associatedtype D: Route

  func deeplink(from route: R) async throws -> DeeplinkRoute<D>?
}
```

Two details in that declaration carry the whole design:

- The input `R` is `Hashable & Sendable`, so it can be handed to an async function safely.
- The method has no isolation annotation. It runs on whatever executor calls it, and it's free to suspend — to fetch the entity a link points at, say — before it answers.

The obvious trap is to treat the handler as "the place where navigation happens" and call the router from inside it. The compiler stops you:

```
error: main actor-isolated instance method 'push()' cannot be called
       from outside of the actor
```

The intended shape is the opposite: the handler *returns data* — a `DeeplinkRoute` describing where to go — and the main-actor caller applies it. This is the pattern used in the demo app:

```swift
.task(id: pendingDeeplink.identifier) {
  guard case let .navigationStack(target) = pendingDeeplink.identifier else { return }
  guard let deeplink = try? await handler.deeplink(from: target) else { return }
  router.handle(deeplink: deeplink)      // @MainActor, resumed on the main actor
  pendingDeeplink.identifier = nil
}
```

`.task` inherits the view's main-actor isolation, so after `await handler.deeplink(from:)` the code resumes on the main actor and `router.handle(deeplink:)` needs no extra hop. All the slow, possibly-off-main work lives in the handler; the single moment that must be on the main actor is the one line that touches the router.

The same split applies to `TabDeeplinkHandler`, which additionally returns the target tab.

---

## Pitfall 6: Context Closures Capturing `self` (This One Isn't a Compiler Error)

I'm including this one precisely because Swift 6 won't help you with it. Registering a handler for a context stores an escaping closure on the router:

```swift
router.add(context: UserSelectionContext.self) { [weak self] context in
  self?.selectedUser = context.user
}
```

If that closure captures `self` strongly and `self` also owns (directly or via SwiftUI state) the router, you've built a retain cycle. There's no diagnostic — strict concurrency is about data races, not about leaks — which is why the docs for `add(context:perform:)` call out `[weak self]` explicitly. Treat it as a code-review item, not a compiler item.

<!-- SORARE: if a leak or lifecycle bug like this showed up during the migration, say so here (one paragraph). If not, delete this comment and leave the section as is. -->

---

## What swift-routing Itself Had to Fix

Being Swift 6-clean isn't free for the library either, and two of the concrete cases are instructive.

**A lock for the children registry.** Routers form a tree, and each one registers itself with its parent in `init` and removes itself in `deinit`. Neither runs on the main actor — a router's last reference can be released from any thread. The registry is therefore guarded by an `NSLock`:

```swift
/// Guards `_children` -- `addChild`/`removeChild` run from `init`/`deinit`, which are not
/// `@MainActor`-isolated, so a router's last reference can be released from any thread.
private let childrenLock = NSLock()
```

This was a real fix, recorded in the changelog: a data race in `addChild`/`removeChild` that could corrupt or crash on concurrent router creation or teardown off the main actor.

**Don't capture `self` from `deinit`.** The logging path can run from `deinit`, and it notifies a shared Combine subject. Capturing `self` in the deferred block would extend the router's lifetime; sending synchronously risks re-entering the same subject. So the code copies just the subject into a `nonisolated(unsafe)` local and sends on the next main-actor hop:

```swift
nonisolated(unsafe) let events = configuration.events
Task { @MainActor in
  events.send()
}
```

Neither of these is something a consumer ever sees, which is the point — but both are the kind of thing that only surfaces once strict concurrency forces you to ask *which thread does this actually run on?*

---

## What I'd Tell Someone Starting This Migration

- **Make routes and contexts value types, early.** It's the single change the compiler will demand most often, and it makes everything else (deep links, tests, analytics) easier.
- **Remember the asymmetry:** the router's mutating methods are main-actor-isolated; the protocols you inject are not. Inject `any RouterModel` and your ViewModels and tests stay free of `@MainActor` boilerplate.
- **Let handlers return data, not perform navigation.** Keep the `await` on one side of the line and the router call on the other.
- **Read the first error only.** Strict concurrency errors cascade; the root cause is almost always the first one.
- **Check isolation inheritance when code moves.** A snippet that compiles inside a `View` can stop compiling the moment it lands in a non-isolated type.

None of this is specific to navigation in theory. In practice, navigation is where values cross screens, where URLs arrive from outside the app, and where UI state meets async work — which is exactly where strict concurrency has the most to say.

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
