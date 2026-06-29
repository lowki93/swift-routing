import Testing
@testable import SwiftRouting

@MainActor
struct RouterContextTests {
  @MainActor
  struct Execute {
    @Test
    func contextExists_execute_return_actionCalledWithPayload() {
      let loggerSpy = LoggerSpy()
      let router = Router(configuration: Configuration(loggerSpy: loggerSpy))
      var received: StringContext?
      let expectedContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { object in
          received = object as? StringContext
        }
      )

      expectedContext.execute(StringContext(value: "42"))

      #expect(received == StringContext(value: "42"))
      #expect(loggerSpy.receivedLoggerConfiguration?.router.id == router.id)
      assertLogMessageKind(loggerSpy, is: .context(.execute(StringContext(value: "42"), from: DefaultRoute.main)))
    }
  }

  @MainActor
  struct First {
    @Test
    func matchingContextExistsAndCurrentRouteDiffers_first_return_context() {
      let currentRouter = Router(configuration: Configuration())
      currentRouter.push(TestRoute.home)
      let expectedCurrentRouteContext = RouterContext(
        router: currentRouter,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let otherRouter = Router(configuration: Configuration())
      otherRouter.push(TestRoute.details(id: "42"))
      let expectedMatchingContext = RouterContext(
        router: otherRouter,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedCurrentRouteContext, expectedMatchingContext]

      let foundContext = contexts.first(
        for: StringContext.self,
        currentRoute: currentRouter.currentRoute.wrapped
      )

      #expect(foundContext == expectedMatchingContext)
    }

    @Test
    func onlyCurrentRouteContextExists_first_return_nil() {
      let router = Router(configuration: Configuration())
      let expectedCurrentRouteContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedCurrentRouteContext]

      let foundContext = contexts.first(
        for: StringContext.self,
        currentRoute: router.currentRoute.wrapped
      )

      #expect(foundContext == nil)
    }

    @Test
    func contextTypeDoesNotMatch_first_return_nil() {
      let router = Router(configuration: Configuration())
      let expectedNonMatchingContext = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedNonMatchingContext]

      let foundContext = contexts.first(
        for: StringContext.self,
        currentRoute: router.currentRoute.wrapped
      )

      #expect(foundContext == nil)
    }
  }

  @MainActor
  struct AllForTerminationType {
    @Test
    func matchingContextsExist_all_return_onlyMatchingContexts() {
      let router = Router(configuration: Configuration())
      let expectedFirstMatching = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let expectedNonMatching = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )

      router.push(TestRoute.settings)

      let expectedSecondMatching = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [expectedFirstMatching, expectedNonMatching, expectedSecondMatching]

      let matchingContexts = contexts.all(for: StringContext.self)

      #expect(matchingContexts.count == 2)
      #expect(matchingContexts.contains(expectedFirstMatching))
      #expect(matchingContexts.contains(expectedSecondMatching))
    }

    @Test
    func noMatchingContextExists_all_return_emptySet() {
      let router = Router(configuration: Configuration())
      let expectedNonMatchingContext = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedNonMatchingContext]

      let matchingContexts = contexts.all(for: StringContext.self)

      #expect(matchingContexts.isEmpty)
    }
  }

  @MainActor
  struct AllForTerminationTypeWithCurrentRoute {
    @Test
    func matchingContextsExistOnDifferentRoutes_allWithCurrentRoute_return_onlyCurrentRouteContexts() {
      let router = Router(configuration: Configuration())
      let expectedRootContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.settings)

      let expectedCurrentRouteContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [expectedRootContext, expectedCurrentRouteContext]
      let matchingContexts = contexts.all(
        for: StringContext.self,
        currentRoute: router.currentRoute.wrapped
      )

      #expect(matchingContexts.count == 1)
      #expect(matchingContexts.contains(expectedCurrentRouteContext))
    }

    @Test
    func noMatchingContextExists_allWithCurrentRoute_return_emptySet() {
      let router = Router(configuration: Configuration())
      let expectedNonMatchingContext = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedNonMatchingContext]

      let matchingContexts = contexts.all(
        for: StringContext.self,
        currentRoute: router.currentRoute.wrapped
      )

      #expect(matchingContexts.isEmpty)
    }

    @Test
    func matchingTypeExistsOnCurrentRoute_allWithCurrentRoute_return_onlyCurrentRouteAndMatchingType() {
      let router = Router(configuration: Configuration())
      let expectedRootStringContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.settings)

      let expectedCurrentRouteStringContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let expectedCurrentRouteIntContext = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [
        expectedRootStringContext,
        expectedCurrentRouteStringContext,
        expectedCurrentRouteIntContext
      ]

      let matchingContexts = contexts.all(
        for: StringContext.self,
        currentRoute: router.currentRoute.wrapped
      )

      #expect(matchingContexts.count == 1)
      #expect(matchingContexts.contains(expectedCurrentRouteStringContext))
    }
  }

  @MainActor
  struct AllForSingleRoute {
    @Test
    func matchingRouteExists_allForRoute_return_onlyContextsForThatRoute() {
      let router = Router(configuration: Configuration())
      let rootContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.home)
      let homeContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [rootContext, homeContext]

      let result = contexts.all(for: TestRoute.home)

      #expect(result.count == 1)
      #expect(result.contains(homeContext))
    }

    @Test
    func noMatchingRouteExists_allForRoute_return_emptySet() {
      let router = Router(configuration: Configuration())
      let rootContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [rootContext]

      let result = contexts.all(for: TestRoute.home)

      #expect(result.isEmpty)
    }

    @Test
    func multipleContextsOnSameRoute_allForRoute_return_allOfThem() {
      let router = Router(configuration: Configuration())
      router.push(TestRoute.home)
      let firstContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let secondContext = RouterContext(
        router: router,
        routerContext: IntContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [firstContext, secondContext]

      let result = contexts.all(for: TestRoute.home)

      #expect(result.count == 2)
      #expect(result.contains(firstContext))
      #expect(result.contains(secondContext))
    }

    @Test
    func emptySet_allForRoute_return_emptySet() {
      let contexts: Set<RouterContext> = []

      let result = contexts.all(for: TestRoute.home)

      #expect(result.isEmpty)
    }
  }

  @MainActor
  struct AllForRoutes {
    @Test
    func matchingRoutesExist_allForRoutes_return_onlyContextsForGivenRoutes() {
      let router = Router(configuration: Configuration())
      let expectedRootContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.home)
      let expectedHomeContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.settings)
      let expectedSettingsContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [expectedRootContext, expectedHomeContext, expectedSettingsContext]
      let matchingContexts = contexts.all(for: [TestRoute.settings])

      #expect(matchingContexts.count == 1)
      #expect(matchingContexts.contains(expectedSettingsContext))
    }

    @Test
    func routesAreEmpty_allForRoutes_return_emptySet() {
      let router = Router(configuration: Configuration())
      let expectedContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedContext]

      let matchingContexts = contexts.all(for: [])

      #expect(matchingContexts.isEmpty)
    }
  }

  @MainActor
  struct FirstForRoute {
    @Test
    func matchingRouteExists_firstForRoute_return_context() {
      let router = Router(configuration: Configuration())
      router.push(TestRoute.home)
      let expectedContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedContext]

      let foundContext = contexts.first(for: TestRoute.home)

      #expect(foundContext == expectedContext)
    }

    @Test
    func noMatchingRouteExists_firstForRoute_return_nil() {
      let router = Router(configuration: Configuration())
      let expectedContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let contexts: Set<RouterContext> = [expectedContext]

      let foundContext = contexts.first(for: TestRoute.home)

      #expect(foundContext == nil)
    }

    @Test
    func multipleContextsExist_firstForRoute_return_matchingOne() {
      let router = Router(configuration: Configuration())
      let rootContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.home)
      let homeContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      router.push(TestRoute.settings)
      let settingsContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      let contexts: Set<RouterContext> = [rootContext, homeContext, settingsContext]

      let foundContext = contexts.first(for: TestRoute.home)

      #expect(foundContext == homeContext)
    }

    @Test
    func emptySet_firstForRoute_return_nil() {
      let contexts: Set<RouterContext> = []

      let foundContext = contexts.first(for: TestRoute.home)

      #expect(foundContext == nil)
    }
  }

  @MainActor
  struct Equality {
    @Test
    func sameRouterRouteAndContextType_equal_return_true() {
      let router = Router(configuration: Configuration())
      let expectedFirstContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )
      let expectedSecondContext = RouterContext(
        router: router,
        routerContext: StringContext.self,
        action: { _ in }
      )

      #expect(expectedFirstContext == expectedSecondContext)
    }
  }
}
