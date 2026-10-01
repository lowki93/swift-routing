# Testing SwiftUI Navigation Without Mounting a Single View

*Part 5 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270) and [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407). Parts 3 and 4 covered tab and split-view navigation — this one is about testing all of it.*

Ask most iOS developers how they test navigation and the honest answer is: they don't, not really. Maybe a UI test clicks through a happy path once. The actual logic — "tapping this button should push that screen" — usually ships unverified, because testing it the obvious way means mounting a view hierarchy, injecting a fake `@Environment`, and asserting on whatever `NavigationPath` happens to look like afterward. That's expensive to write and brittle to maintain, so most teams just... don't.

`swift-routing` was built so that doesn't have to be the tradeoff. Navigation intent is a protocol call (`router.push(_:)`, `router.present(_:)`), and protocol calls can be recorded by a test double, same as any other dependency.

---

## The Problem: Navigation Logic Usually Lives Where You Can't Reach It

The most common shape of SwiftUI navigation code puts the decision directly in the view:

```swift
struct ProfileScreen: View {
  @Environment(\.router) private var router

  var body: some View {
    Button("Edit") {
      router.push(AppRoute.editProfile)
    }
  }
}
```

To verify that tapping "Edit" pushes the right route, you'd need to render `ProfileScreen`, inject a router into its environment, simulate a tap, then inspect whatever that router ended up with — a view-hosting test, slow and fiddly, for a one-line assertion about *intent*. The view itself doesn't need testing here; the `AppRoute.editProfile` decision does.

---

## RouterSpy: A RouterModel That Records Instead of Navigates

`SwiftRoutingTestSupport` ships `RouterSpy`, a test double conforming to the full `RouterModel` protocol — push, present, cover, context handling, split selections, all of it — that records every call instead of performing real navigation:

```swift
import SwiftRoutingTestSupport

let spy = RouterSpy(root: AppRoute.home)
spy.push(AppRoute.profile(userId: "123"))

#expect(spy.pushedRoutes.count == 1)
#expect((spy.pushedRoutes.first as? AppRoute) == .profile(userId: "123"))
```

`pushedRoutes`, `presentedRoutes`, `coveredRoutes`, `updatedRoots`, `backCallCount`, `popToRootCallCount`, `closeCallCount`, `terminatedContexts`, `dispatchedContexts`, `contentSelections`, `detailSelections` — the full surface of `RouterModel` has a recorded counterpart. `RouterModel` is a protocol with real breadth by now (push, present, cover, context handling, split selections), and a hand-rolled mock for it silently drifts out of sync every time the protocol grows a member. `RouterSpy` is tested against the real protocol, so it can't drift the way a one-off mock would.

One honest limitation: `tabRouter(for:)`, `findRouterInTabRouter(for:)`, and `deepestRouter()` always return `nil` on a spy — there's no real router hierarchy behind it. Code that genuinely needs to walk a router tree still wants a real `Router` in the test.

---

## The Pattern That Makes This Possible: Inject, Don't Reach

A spy is only useful if the code under test can receive one instead of a real router — which means the navigation decision has to live somewhere other than `@Environment(\.router)` read straight from a view's `body`. The fix is a ViewModel that takes `any RouterModel` through its initializer:

```swift
final class UserScreenModel {
  private(set) var name: String
  private let router: any RouterModel

  init(name: String, router: any RouterModel) {
    self.name = name
    self.router = router
  }

  func pushBen() {
    router.push(AppRoute.user(name: "Ben"))
  }

  func back() {
    router.back()
  }

  func popToRoot() {
    router.popToRoot()
  }
}
```

(This is real, shipped code from the swift-routing demo app — not a simplified stand-in.) The view still reads `@Environment(\.router)`, but only once, to construct the real `Router` and hand it to the model; every navigation decision from then on goes through `any RouterModel`, a protocol a spy can stand in for just as well as the real thing.

```swift
// Avoid: concrete type, impossible to substitute in a test
init(router: Router) { ... }

// Good: protocol type, a RouterSpy drops right in
init(router: any RouterModel) { ... }
```

---

## A Complete Example: Testing a Button's Navigation Intent

Put the two together and a navigation test is a handful of lines, no view in sight:

```swift
import Testing
import SwiftRoutingTestSupport

@Suite("UserScreenModel Navigation")
struct UserScreenModelTests {

  @Test
  @MainActor
  func pushBen_pushesUserRoute() {
    let spy = RouterSpy(root: AppRoute.home)
    let model = UserScreenModel(name: "Ben", router: spy)

    model.pushBen()

    #expect(spy.pushedRoutes.count == 1)
    #expect((spy.pushedRoutes.first as? AppRoute) == .user(name: "Ben"))
  }

  @Test
  @MainActor
  func popToRoot_popsToRoot() {
    let spy = RouterSpy(root: AppRoute.home)
    let model = UserScreenModel(name: "Ben", router: spy)

    model.popToRoot()

    #expect(spy.popToRootCallCount == 1)
  }
}
```

Favor asserting on *intent* over implementation. `spy.pushedRoutes.contains { ($0 as? AppRoute) == .user(name: "Ben") }` says what the test actually cares about; a count on `spy.pathCount` (how deep the stack got) ties the test to internal bookkeeping that has nothing to do with the behavior you're verifying.

---

## Testing RouteContext and terminate()

The `RouteContext` pattern from [Part 2](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407) is just as testable, in two separate halves: the child firing a context, and the parent reacting to one.

Sending a context from a ViewModel is another spy assertion, same shape as a push:

```swift
@Test
@MainActor
func selectUser_terminatesWithContext() {
  let spy = RouterSpy(root: AppRoute.userPicker)
  let viewModel = UserPickerViewModel(router: spy)
  let user = User(id: "1", name: "John")

  viewModel.selectUser(user)

  #expect(spy.terminatedContexts.count == 1)
  let context = spy.terminatedContexts.first as? UserSelectionContext
  #expect(context?.selectedUser.id == "1")
}
```

*Receiving* a context, on the other hand, needs a real `Router` — a spy has nowhere to route a registered handler to, since `add(context:perform:)`/`context(_:)` are about one router's own bookkeeping, not a call to record:

```swift
@Test
@MainActor
func contextHandler_receivesContext() async {
  let router = Router(configuration: .default)
  var receivedUser: User?

  router.add(context: UserSelectionContext.self) { context in
    receivedUser = context.selectedUser
  }

  router.context(UserSelectionContext(selectedUser: .init(id: "1", name: "John")))

  #expect(receivedUser?.id == "1")
}
```

That split — spy for *sending*, real router for *receiving* — is the same rule of thumb as the `tabRouter(for:)` limitation above: anything that's genuinely a call out gets recorded by the spy; anything that depends on a live router's own state needs the real thing.

---

## Testing Across Tabs: TabRouterSpy

`TabRouterSpy`, from the same package, conforms to `TabRouterModel` the same way `RouterSpy` conforms to `RouterModel` — push/present/cover land in the recorded arrays, but each entry also carries which tab it targeted:

```swift
@Test
@MainActor
func crossTabNavigation_pushesToCorrectTab() {
  let spy = TabRouterSpy(root: AppRoute.home)
  let viewModel = HomeViewModel(tabRouter: spy)

  viewModel.goToProfile(userId: "123")

  #expect(spy.pushedRoutes.count == 1)
  let call = spy.pushedRoutes.first
  #expect((call?.route as? AppRoute) == .profile(userId: "123"))
  #expect((call?.tab as? AppTab) == .profile)
}
```

That second assertion — which tab the push targeted, not just which route — is exactly the kind of thing that's tedious to verify through a mounted view and free once the test is just reading a recorded array.

---

## Before and After

**Before — can't test this without a window:**

```swift
struct ProfileScreen: View {
  @Environment(\.router) private var router

  var body: some View {
    Button("Edit") {
      router.push(AppRoute.editProfile)
    }
  }
}
```

**After — the decision moved out of the view, and testing it is three lines:**

```swift
final class ProfileViewModel {
  private let router: any RouterModel
  init(router: any RouterModel) { self.router = router }
  func editProfile() { router.push(AppRoute.editProfile) }
}

let spy = RouterSpy(root: AppRoute.profile)
ProfileViewModel(router: spy).editProfile()
#expect((spy.pushedRoutes.first as? AppRoute) == .editProfile)
```

Nothing about the *view* changed in spirit — `Button("Edit") { viewModel.editProfile() }` reads just as plainly as the original. What changed is that the one line that decides *where "Edit" goes* now lives somewhere a test can reach it directly.

---

## Why This Matters

The reason navigation usually goes untested isn't that it doesn't matter — a button pushing the wrong screen is a real, user-facing bug. It's that the obvious way to test it is expensive enough that it quietly stops happening. Moving the decision behind a protocol and recording calls instead of performing them removes that cost entirely: no view hierarchy, no simulated taps, no `@Environment` to fake — just a spy and an assertion about what was supposed to happen.

That's the whole idea behind `RouterModel`/`TabRouterModel` being protocols in the first place, not an afterthought bolted on for tests: the same seam that lets `RouterSpy` stand in for a `Router` is the one that makes the real thing work.

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
