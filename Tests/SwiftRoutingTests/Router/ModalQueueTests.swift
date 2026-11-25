import Combine
@testable import SwiftRouting
import Testing

/// A modal requested while another one is still dismissing is held by the router and presented once
/// SwiftUI reports the dismissal (`notifyModalDismissed`), because UIKit drops it otherwise.
@MainActor
struct ModalQueueTests {

  @MainActor
  struct NothingDismissing {
    let screen = ModalScreen()

    @Test(arguments: ModalKind.allCases)
    func modalRequested_return_presentedImmediately(kind: ModalKind) {
      kind.request(.home, on: screen.router)

      #expect(screen.modal(kind) == .home)
    }

    @Test
    func coverOnScreen_anotherCoverRequested_return_replacedImmediately() {
      screen.show(.home, as: .cover)

      screen.router.cover(TestRoute.settings)

      #expect(screen.cover == .settings)
    }

    @Test
    func modalSetAndClearedBeforeShown_nextRequest_return_presentedImmediately() {
      screen.router.cover(TestRoute.home)
      screen.router.cover = nil

      screen.router.cover(TestRoute.settings)

      #expect(screen.cover == .settings)
    }
  }

  @MainActor
  struct Holding {
    let screen = ModalScreen()

    @Test(arguments: ModalKind.allCases, ModalKind.allCases)
    func modalDismissing_modalRequested_return_heldUntilDismissalReported(dismissing: ModalKind, requested: ModalKind) {
      screen.show(.home, as: dismissing)
      screen.startDismissing(dismissing)

      requested.request(.settings, on: screen.router)
      #expect(screen.sheet == nil)
      #expect(screen.cover == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.modal(requested) == .settings)
    }

    @Test
    func modalDismissing_coverRequested_return_navigationLoggedOnlyOnceShown() {
      let loggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedRouter = Router(configuration: Configuration(loggerSpy: loggerSpy))
      let screen = ModalScreen(router: expectedRouter)
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      loggerSpy.clearReceivedMessages()

      expectedRouter.cover(TestRoute.settings)
      #expect(loggerSpy.receivedMessages.isEmpty)

      expectedRouter.notifyModalDismissed()
      assertLogMessageKind(loggerSpy, is: .navigation(from: DefaultRoute.main, to: TestRoute.settings, type: .cover))
      #expect(loggerSpy.receivedRouterId == expectedRouter.id)
      #expect(loggerSpy.receivedCallCount == 1)
    }

    @Test
    func modalHeld_return_presentPublisherSendsTrueOnceShown() {
      var receivedEvents: [Bool] = []
      var cancellables = Set<AnyCancellable>()
      screen.show(.home, as: .cover)
      screen.router.present.sink { isPresented, _ in receivedEvents.append(isPresented) }.store(in: &cancellables)
      screen.startDismissing(.cover)
      screen.router.cover(TestRoute.settings)
      #expect(receivedEvents == [false])

      screen.router.notifyModalDismissed()

      #expect(receivedEvents == [false, true])
    }

    @Test
    func presentFalseObserverRequestsModal_return_heldUntilDismissalReported() {
      var cancellables = Set<AnyCancellable>()
      screen.show(.home, as: .cover)
      screen.router.present
        .sink { [router = screen.router] isPresented, _ in
          if !isPresented { router.cover(TestRoute.settings) }
        }
        .store(in: &cancellables)

      screen.startDismissing(.cover)
      #expect(screen.cover == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.cover == .settings)
    }

    @Test
    func coverOnScreen_coverDeeplink_return_presentedOnceDismissalReported() {
      screen.show(.home, as: .cover)

      screen.router.handle(deeplink: DeeplinkRoute.cover(TestRoute.settings))
      #expect(screen.cover == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.cover == .settings)
    }

    @Test
    func sheetDismissing_coverDeeplink_return_presentedOnceDismissalReported() {
      screen.show(.home, as: .sheet)
      screen.startDismissing(.sheet)

      screen.router.handle(deeplink: DeeplinkRoute.cover(TestRoute.settings))
      #expect(screen.cover == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.cover == .settings)
    }

    @Test
    func modalDismissing_coverRouteCalled_return_heldUntilDismissalReported() {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)

      screen.router.route(TestDispatchRoute.covered)
      #expect(screen.router.cover == nil)

      screen.router.notifyModalDismissed()
      #expect((screen.router.cover?.wrapped as? TestDispatchRoute) == .covered)
    }

    @Test(arguments: [(TestDispatchRoute.sheetWithStack, true), (.sheetWithoutStack, false)])
    func modalDismissing_sheetRouteCalled_return_heldUntilDismissalReported(
      route: TestDispatchRoute,
      expectedInStack: Bool
    ) {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)

      screen.router.route(route)
      #expect(screen.router.sheet == nil)

      screen.router.notifyModalDismissed()
      #expect((screen.router.sheet?.wrapped as? TestDispatchRoute) == route)
      #expect(screen.router.sheet?.inStack == expectedInStack)
    }

    @Test
    func presentedRouterChangedItsRoot_modalDismissing_return_requestHeld() {
      let child = screen.show(.home, as: .sheet)
      child.update(root: TestRoute.settings)
      screen.startDismissing(.sheet)

      screen.router.cover(TestRoute.details(id: "next"))
      #expect(screen.cover == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.cover == .details(id: "next"))
    }

    @Test
    func sheetClosedByCloseChildren_sameSheetRequested_return_presentedAgainOnceDismissed() {
      screen.show(.home, as: .sheet)

      screen.router.closeChildren()
      screen.router.present(TestRoute.home)
      #expect(screen.sheet == nil)

      screen.router.notifyModalDismissed()
      #expect(screen.sheet == .home)
    }

    @Test
    func dismissalReported_nextRequest_return_presentedImmediately() {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.notifyModalDismissed()

      screen.router.cover(TestRoute.settings)

      #expect(screen.cover == .settings)
    }
  }

  @MainActor
  struct Replacing {
    let screen = ModalScreen()

    @Test
    func secondRequestWhileHeld_return_onlyLatestPresented() {
      var shownCovers: [TestRoute] = []
      var cancellables = Set<AnyCancellable>()
      screen.show(.home, as: .cover)
      screen.router.present
        .sink { [screen] isPresented, _ in
          if isPresented, let cover = screen.cover { shownCovers.append(cover) }
        }
        .store(in: &cancellables)
      screen.startDismissing(.cover)

      screen.router.cover(TestRoute.settings)
      screen.router.cover(TestRoute.details(id: "latest"))
      screen.router.notifyModalDismissed()

      #expect(shownCovers == [.details(id: "latest")])
    }

    @Test
    func coverThenSheetRequestedWhileHeld_return_onlySheetPresented() {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)

      screen.router.cover(TestRoute.settings)
      screen.router.present(TestRoute.details(id: "sheet"))
      screen.router.notifyModalDismissed()

      #expect(screen.cover == nil)
      #expect(screen.sheet == .details(id: "sheet"))
    }

    @Test
    func dismissedObserverRequestsModal_return_presentedImmediately() {
      var cancellables = Set<AnyCancellable>()
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.dismissed
        .sink { [router = screen.router] _ in router.cover(TestRoute.details(id: "from-observer")) }
        .store(in: &cancellables)

      screen.router.notifyModalDismissed()

      #expect(screen.cover == .details(id: "from-observer"))
    }

    @Test
    func dismissedObserverRequestsModal_return_replacesHeldRequest() {
      var cancellables = Set<AnyCancellable>()
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.cover(TestRoute.settings)
      screen.router.dismissed
        .sink { [router = screen.router] _ in router.cover(TestRoute.details(id: "from-observer")) }
        .store(in: &cancellables)

      screen.router.notifyModalDismissed()

      #expect(screen.cover == .details(id: "from-observer"))
    }
  }

  @MainActor
  struct Dropping {
    let screen = ModalScreen()

    @Test
    func requestHeld_closeChildren_return_requestDropped() {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.cover(TestRoute.settings)

      screen.router.closeChildren()
      screen.router.notifyModalDismissed()

      #expect(screen.cover == nil)
    }

    @Test
    func requestHeld_presentedRouterClosed_return_requestDropped() {
      let modal = screen.show(.home, as: .sheet)
      let modalScreen = ModalScreen(router: modal)
      modalScreen.show(.settings, as: .cover)
      modalScreen.startDismissing(.cover)
      modal.cover(TestRoute.details(id: "held"))
      #expect(modalScreen.cover == nil)

      modal.close()
      modal.notifyModalDismissed()

      #expect(modalScreen.cover == nil)
    }
  }

  /// A dismissal that SwiftUI never reports must not hold the router forever.
  @MainActor
  struct NeverStuck {
    let screen = ModalScreen()

    @Test
    func leftoverRouterOfSameRoute_modalSetAndClearedInOneTurn_return_nextRequestPresented() {
      screen.show(.home, as: .sheet)
      screen.startDismissing(.sheet)
      screen.router.notifyModalDismissed()

      screen.router.present(TestRoute.home)
      screen.router.closeChildren()
      screen.router.cover(TestRoute.settings)

      #expect(screen.cover == .settings)
    }

    @Test
    func leftoverRouterOfReplacedModal_modalSetAndClearedInOneTurn_return_nextRequestPresented() {
      screen.show(.home, as: .sheet)
      screen.show(.settings, as: .sheet)

      screen.router.present(TestRoute.home)
      screen.router.sheet = nil
      screen.router.cover(TestRoute.details(id: "next"))

      #expect(screen.cover == .details(id: "next"))
    }

    @Test
    func dismissalNeverReported_presentedContentDisappeared_return_heldRequestPresented() {
      let child = screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.cover(TestRoute.settings)
      #expect(screen.cover == nil)

      child.notifyContentDisappeared()

      #expect(screen.cover == .settings)
    }

    @Test
    func dismissalInFlight_leftoverRouterContentDisappeared_return_requestStillHeld() {
      let leftover = screen.show(.home, as: .sheet)
      screen.startDismissing(.sheet)
      screen.router.notifyModalDismissed()
      let dismissingChild = screen.show(.settings, as: .sheet)
      screen.startDismissing(.sheet)
      screen.router.cover(TestRoute.details(id: "held"))

      leftover.notifyContentDisappeared()
      #expect(screen.cover == nil)

      dismissingChild.notifyContentDisappeared()
      #expect(screen.cover == .details(id: "held"))
    }

    @Test
    func dismissingRouterReleased_dismissalNeverReported_return_heldRequestPresented() async {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.router.cover(TestRoute.settings)
      #expect(screen.cover == nil)

      screen.releaseChildren()
      // The release presents the held modal from a main-actor task enqueued before this one resumes.
      await Task.yield()

      #expect(screen.cover == .settings)
    }

    @Test
    func dismissingRouterReleased_dismissalNeverReported_return_nextRequestPresentedImmediately() {
      screen.show(.home, as: .cover)
      screen.startDismissing(.cover)
      screen.releaseChildren()

      screen.router.cover(TestRoute.settings)

      #expect(screen.cover == .settings)
    }
  }
}
