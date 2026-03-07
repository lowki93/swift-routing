# Testing Navigation

Learn how to write unit tests for your navigation logic.

## Overview

SwiftRouting is designed with testability in mind. The protocol-based architecture allows you to mock routers and verify navigation behavior without running UI tests.

## Testing Strategies

### Strategy 1: Mock RouterModel

Create a mock implementation of ``RouterModel`` to capture navigation calls:

```swift
@MainActor
final class MockRouter: RouterModel {
    var pushedRoutes: [any Route] = []
    var presentedRoutes: [any Route] = []
    var coveredRoutes: [any Route] = []
    var backCallCount = 0
    var popToRootCallCount = 0
    var closeCallCount = 0
    
    func push(_ route: some Route) {
        pushedRoutes.append(route)
    }
    
    func present(_ route: some Route, withStack: Bool = true) {
        presentedRoutes.append(route)
    }
    
    func cover(_ route: some Route) {
        coveredRoutes.append(route)
    }
    
    func back() {
        backCallCount += 1
    }
    
    func popToRoot() {
        popToRootCallCount += 1
    }
    
    func close() {
        closeCallCount += 1
    }
    
    // Implement other RouterModel requirements as needed
    func route(_ route: some Route) {
        push(route)
    }
    
    func route(to route: some Route, type: RoutingType) {
        switch type {
        case .push: push(route)
        case .sheet: present(route)
        case .cover: cover(route)
        case .root: break
        }
    }
    
    func update(root route: some Route) {}
    func closeChildren() {}
    func add<T: RouteContext>(context: T.Type, action: @escaping (T) -> Void) {}
    func remove<T: RouteContext>(context: T.Type) {}
    func context(_ object: some RouteContext) {}
    func terminate(_ object: some RouteContext) {}
}
```

### Strategy 2: Test ViewModel Navigation

Inject the mock router into your ViewModel:

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
        let mockRouter = MockRouter()
        let viewModel = ProfileViewModel(router: mockRouter, userId: "123")
        
        viewModel.editProfile()
        
        #expect(mockRouter.pushedRoutes.count == 1)
        let pushedRoute = mockRouter.pushedRoutes.first as? ProfileRoute
        #expect(pushedRoute == .edit(userId: "123"))
    }
    
    @Test
    @MainActor
    func openSettings_presentsSettingsRoute() {
        let mockRouter = MockRouter()
        let viewModel = ProfileViewModel(router: mockRouter, userId: "123")
        
        viewModel.openSettings()
        
        #expect(mockRouter.presentedRoutes.count == 1)
        let presentedRoute = mockRouter.presentedRoutes.first as? ProfileRoute
        #expect(presentedRoute == .settings)
    }
    
    @Test
    @MainActor
    func logout_popsToRoot() {
        let mockRouter = MockRouter()
        let viewModel = ProfileViewModel(router: mockRouter, userId: "123")
        
        viewModel.logout()
        
        #expect(mockRouter.popToRootCallCount == 1)
    }
}
```

## Testing RouteContext

### Testing Context Sending

```swift
@MainActor
final class MockRouterWithContext: MockRouter {
    var sentContexts: [any RouteContext] = []
    var terminatedContexts: [any RouteContext] = []
    
    override func context(_ object: some RouteContext) {
        sentContexts.append(object)
    }
    
    override func terminate(_ object: some RouteContext) {
        terminatedContexts.append(object)
    }
}

@Test
@MainActor
func selectUser_terminatesWithContext() {
    let mockRouter = MockRouterWithContext()
    let viewModel = UserPickerViewModel(router: mockRouter)
    let user = User(id: "1", name: "John")
    
    viewModel.selectUser(user)
    
    #expect(mockRouter.terminatedContexts.count == 1)
    let context = mockRouter.terminatedContexts.first as? UserSelectionContext
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

```swift
@MainActor
final class MockTabRouter: TabRouterModel {
    var selectedTab: (any TabRoute)?
    var pushCalls: [(route: any Route, tab: (any TabRoute)?)] = []
    var popToRootCalls: [(any TabRoute)?] = []
    
    func change(tab: some TabRoute) {
        selectedTab = tab
    }
    
    func push(_ route: some Route, in tab: (any TabRoute)?) {
        pushCalls.append((route, tab))
    }
    
    func popToRoot(in tab: (any TabRoute)?) {
        popToRootCalls.append(tab)
    }
    
    // Implement other TabRouterModel requirements...
}

@Test
@MainActor
func crossTabNavigation_pushesToCorrectTab() {
    let mockTabRouter = MockTabRouter()
    let viewModel = HomeViewModel(tabRouter: mockTabRouter)
    
    viewModel.goToProfile(userId: "123")
    
    #expect(mockTabRouter.pushCalls.count == 1)
    let call = mockTabRouter.pushCalls.first
    #expect((call?.route as? AppRoute) == .profile(userId: "123"))
    #expect((call?.tab as? AppTab) == .profile)
}
```

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
#expect(mockRouter.pushedRoutes.contains { ($0 as? AppRoute) == .profile(userId: "123") })

// Avoid: Testing implementation details
#expect(mockRouter.path.count == 2)
```

### Keep Mocks Simple

Only implement what you need for each test. Use `fatalError()` for unneeded methods during development to catch unexpected calls.

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
