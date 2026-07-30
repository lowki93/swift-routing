# Testing Navigation

Learn how to write unit tests for your navigation logic.

## Overview

SwiftRouting is designed with testability in mind. The protocol-based architecture allows you to mock routers and verify navigation behavior without running UI tests.

## Testing Strategies

### Strategy 1: RouterSpy

`RouterModel` has grown a fair amount of surface (push, present, cover, context handling, split selections...), so hand-rolling a mock for every test is tedious and easy to let drift out of sync with the protocol. Add the companion package instead:

```swift
dependencies: [
    .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "0.2.0"))
]
```

```swift
.product(name: "SwiftRoutingTestSupport", package: "swift-routing")
```

`RouterSpy` conforms to `RouterModel` and records every call instead of performing real navigation:

```swift
import SwiftRoutingTestSupport

let spy = RouterSpy(root: AppRoute.home)
spy.push(AppRoute.profile(userId: "123"))

#expect(spy.pushedRoutes.count == 1)
#expect((spy.pushedRoutes.first as? AppRoute) == .profile(userId: "123"))
```

Available recorded state: `pushedRoutes`, `presentedRoutes`, `coveredRoutes`, `updatedRoots`, `routedDestinations`, `backCallCount`, `popToRootCallCount`, `closeCallCount`, `closeChildrenCallCount`, `terminatedContexts`, `dispatchedContexts`, `addedContextTypes`, `removedContextTypes`, `detailSelections`, `contentSelections` — plus live `currentRoute`/`pathCount`/`detailSelection`/`contentSelection` that update as calls happen.

> Note:
> `tabRouter(for:)`, `findRouterInTabRouter(for:)`, and `deepestRouter()` always return `nil` on `RouterSpy` — there's no real router hierarchy behind it. Test code that depends on those against a real `Router` instead.

### Strategy 2: Test ViewModel Navigation

Inject the spy into your ViewModel:

```swift
@MainActor
final class ProfileViewModel {
    private let router: any RouterModel
    private let userId: String
    
    init(router: any RouterModel, userId: String) {
        self.router = router
        self.userId = userId
    }
    
    func editProfile() {
        router.push(ProfileRoute.edit(userId: userId))
    }
    
    func openSettings() {
        router.present(ProfileRoute.settings)
    }
    
    func logout() {
        router.popToRoot()
    }
}
```

Test the navigation behavior:

```swift
import Testing

@Suite("ProfileViewModel Navigation")
struct ProfileViewModelTests {
    
    @Test
    @MainActor
    func editProfile_pushesEditRoute() {
        let spy = RouterSpy(root: ProfileRoute.overview)
        let viewModel = ProfileViewModel(router: spy, userId: "123")
        
        viewModel.editProfile()
        
        #expect(spy.pushedRoutes.count == 1)
        let pushedRoute = spy.pushedRoutes.first as? ProfileRoute
        #expect(pushedRoute == .edit(userId: "123"))
    }
    
    @Test
    @MainActor
    func openSettings_presentsSettingsRoute() {
        let spy = RouterSpy(root: ProfileRoute.overview)
        let viewModel = ProfileViewModel(router: spy, userId: "123")
        
        viewModel.openSettings()
        
        #expect(spy.presentedRoutes.count == 1)
        let presentedRoute = spy.presentedRoutes.first?.route as? ProfileRoute
        #expect(presentedRoute == .settings)
    }
    
    @Test
    @MainActor
    func logout_popsToRoot() {
        let spy = RouterSpy(root: ProfileRoute.overview)
        let viewModel = ProfileViewModel(router: spy, userId: "123")
        
        viewModel.logout()
        
        #expect(spy.popToRootCallCount == 1)
    }
}
```

## Testing RouteContext

### Testing Context Sending

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

### Testing Context Reception

For testing context handlers, use a real ``Router`` instance:

```swift
@Test
@MainActor
func contextHandler_receivesContext() async {
    let router = Router(configuration: .default)
    var receivedUser: User?
    
    router.add(context: UserSelectionContext.self) { context in
        receivedUser = context.selectedUser
    }
    
    let user = User(id: "1", name: "John")
    router.context(UserSelectionContext(selectedUser: user))
    
    #expect(receivedUser?.id == "1")
}
```

## Testing Deep Links

### Testing DeeplinkHandler

```swift
struct TestDeeplinkHandler: DeeplinkHandler {
    typealias R = DeeplinkIdentifier
    typealias D = AppRoute
    
    func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<AppRoute>? {
        switch route {
        case .home:
            return .push(.home)
        case .profile(let userId):
            return .push(.profile(userId: userId))
        case .settings:
            return .present(.settings)
        default:
            return nil
        }
    }
}

@Suite("DeeplinkHandler")
struct DeeplinkHandlerTests {
    
    @Test
    func homeIdentifier_returnsPushHome() async throws {
        let handler = TestDeeplinkHandler()
        
        let deeplink = try await handler.deeplink(from: .home)
        
        #expect(deeplink?.route == .home)
        #expect(deeplink?.type == .push)
    }
    
    @Test
    func profileIdentifier_returnsPushWithUserId() async throws {
        let handler = TestDeeplinkHandler()
        
        let deeplink = try await handler.deeplink(from: .profile(userId: "123"))
        
        #expect(deeplink?.route == .profile(userId: "123"))
        #expect(deeplink?.type == .push)
    }
    
    @Test
    func settingsIdentifier_returnsPresent() async throws {
        let handler = TestDeeplinkHandler()
        
        let deeplink = try await handler.deeplink(from: .settings)
        
        #expect(deeplink?.route == .settings)
        #expect(deeplink?.type == .sheet(withStack: true))
    }
    
    @Test
    func unknownIdentifier_returnsNil() async throws {
        let handler = TestDeeplinkHandler()
        
        let deeplink = try await handler.deeplink(from: .unknown)
        
        #expect(deeplink == nil)
    }
}
```

### Testing DeeplinkRoute Factories

```swift
@Suite("DeeplinkRoute Factories")
struct DeeplinkRouteFactoryTests {
    
    @Test
    func push_createsCorrectDeeplink() {
        let deeplink: DeeplinkRoute<AppRoute> = .push(.home, path: [.list])
        
        #expect(deeplink.route == .home)
        #expect(deeplink.type == .push)
        #expect(deeplink.path.count == 1)
    }
    
    @Test
    func popToRoot_hasNilRoute() {
        let deeplink: DeeplinkRoute<AppRoute> = .popToRoot()
        
        #expect(deeplink.route == nil)
    }
    
    @Test
    func popToRootWithRoot_setsRoot() {
        let deeplink: DeeplinkRoute<AppRoute> = .popToRoot(root: .dashboard)
        
        #expect(deeplink.root == .dashboard)
        #expect(deeplink.route == nil)
    }
}
```

## Testing TabRouter Navigation

`TabRouterSpy`, from the same `SwiftRoutingTestSupport` package, conforms to `TabRouterModel` the same way:

```swift
import SwiftRoutingTestSupport

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

Available recorded state: `changedTabs`, `pushedRoutes`, `presentedRoutes`, `coveredRoutes`, `updatedRoots`, `popToRootTabs`.

## Best Practices

### Use Protocol Types

Always inject `any RouterModel` or `any TabRouterModel` instead of concrete types:

```swift
// Good: Protocol type enables mocking
init(router: any RouterModel) { ... }

// Avoid: Concrete type is harder to test
init(router: Router) { ... }
```

### Test Navigation Intent, Not Implementation

Focus on *what* navigation should happen, not *how*:

```swift
// Good: Tests the intent
#expect(spy.pushedRoutes.contains { ($0 as? AppRoute) == .profile(userId: "123") })

// Avoid: Testing implementation details
#expect(spy.pathCount == 2)
```

### Prefer RouterSpy Over Hand-Rolled Mocks

`RouterModel`/`TabRouterModel` have grown a fair amount of surface, and a hand-rolled mock silently drifts out of sync every time the protocol changes. `RouterSpy`/`TabRouterSpy` are tested against the real protocols, so use them instead of writing your own unless a test needs custom behavior a spy can't express.

### Test Async Handlers

Deep link handlers are async. Use Swift Testing's async support:

```swift
@Test
func asyncDeeplinkHandler() async throws {
    let handler = MyDeeplinkHandler()
    let result = try await handler.deeplink(from: .someIdentifier)
    #expect(result != nil)
}
```

## Topics

### Related

- ``RouterModel``
- ``TabRouterModel``
- ``DeeplinkHandler``
- ``RouteContext``
