import Testing
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
@testable import SwiftRoutingMacrosPlugin

@Suite("TabRoutableMacro expansion")
struct TabRoutableMacroExpansionTests {

  @Suite("Players (positional associated values + member access)")
  struct Players {
    @Test
    func positionalTemplate_expands_toSwitchWithArgBindings() {
      assertExpansion(
        """
        @TabRoutable
        enum PlayersTab {
          @RouteName(#"Players(\\(arg0))"#)
          case list(PlayerType)
          @RouteName(#"Player(\\(arg0.name))"#)
          case detail(Player)
        }
        """,
        expandedSource: """
          enum PlayersTab {
            case list(PlayerType)
            case detail(Player)

            var name: String {
              switch self {
              case .list(let arg0):
                "Players(\\(arg0))"
              case .detail(let arg0):
                "Player(\\(arg0.name))"
              }
            }
          }

          extension PlayersTab: TabRoute {
          }
          """
      )
    }
  }

  @Suite("Form (constant templates)")
  struct Form {
    @Test
    func constantTemplates_expand_toLiteralCases() {
      assertExpansion(
        """
        @TabRoutable
        enum FormTab {
          @RouteName(#"FormFlow"#)
          case flow
          @RouteName(#"Form"#)
          case entry
        }
        """,
        expandedSource: """
          enum FormTab {
            case flow
            case entry

            var name: String {
              switch self {
              case .flow:
                "FormFlow"
              case .entry:
                "Form"
              }
            }
          }

          extension FormTab: TabRoute {
          }
          """
      )
    }
  }

  @Suite("Notifications (labeled interpolation + delegate)")
  struct Notifications {
    @Test
    func labeledInterpolation_expands_withLabelBinding() {
      assertExpansion(
        """
        @TabRoutable
        enum NotificationsTab {
          @RouteName(#"Notifications"#)
          case list
          @RouteName(#"Notification(\\(id))"#)
          case detail(id: Int)
        }
        """,
        expandedSource: """
          enum NotificationsTab {
            case list
            case detail(id: Int)

            var name: String {
              switch self {
              case .list:
                "Notifications"
              case .detail(let id):
                "Notification(\\(id))"
              }
            }
          }

          extension NotificationsTab: TabRoute {
          }
          """
      )
    }

    @Test
    func delegateCase_expands_toChildNameComposition() {
      assertExpansion(
        """
        @TabRoutable(nameStyle: .capitalized)
        enum AppTab {
          @RouteName(.delegate)
          case notifications(NotificationsRoute)
        }
        """,
        expandedSource: """
          enum AppTab {
            case notifications(NotificationsRoute)

            var name: String {
              switch self {
              case .notifications(let arg0):
                "Notifications.\\(arg0.name)"
              }
            }
          }

          extension AppTab: TabRoute {
          }
          """
      )
    }
  }

  @Suite("nameStyle")
  struct NameStyleTests {
    @Test
    func capitalizedStyle_simpleCases_expand_withoutOverride() {
      assertExpansion(
        """
        @TabRoutable(nameStyle: .capitalized)
        enum AppTab {
          case profile
          case search
        }
        """,
        expandedSource: """
          enum AppTab {
            case profile
            case search

            var name: String {
              switch self {
              case .profile:
                "Profile"
              case .search:
                "Search"
              }
            }
          }

          extension AppTab: TabRoute {
          }
          """
      )
    }

    @Test
    func verbatimStyle_simpleCase_expands_verbatim() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          case home
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }
  }

  @Suite("TabRoute conformance")
  struct Conformance {
    @Test
    func enumWithoutExplicitTabRouteConformance_expands_extensionAddingTabRoute() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          case home
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        conformances: ["TabRoute"]
      )
    }

    @Test
    func enumWithExplicitTabRouteConformance_expands_noRedundantExtension() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab: TabRoute {
          case home
        }
        """,
        expandedSource: """
          enum HomeTab: TabRoute {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }
          """,
        conformances: []
      )
    }

    @Test
    func enumWithExplicitRouteConformance_expands_extensionAddingTabRoute() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab: Route {
          case home
        }
        """,
        expandedSource: """
          enum HomeTab: Route {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        conformances: ["TabRoute"]
      )
    }
  }

  @Suite("hideTabBarOnPush")
  struct HideTabBarOnPushTests {
    @Test
    func noMarkedCase_expands_nameOnly() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          case home
          case profile
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home
            case profile

            var name: String {
              switch self {
              case .home:
                "home"
              case .profile:
                "profile"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func someMarkedCases_expand_toPerCaseSwitch() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case home
          case notifications
          case profile
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home
            case notifications
            case profile

            var name: String {
              switch self {
              case .home:
                "home"
              case .notifications:
                "notifications"
              case .profile:
                "profile"
              }
            }

            var hideTabBarOnPush: Bool {
              switch self {
              case .home:
                true
              case .notifications:
                false
              case .profile:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func allCasesMarked_expand_toConstantTrue() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case home
          @HideTabBarOnPush
          case profile
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home
            case profile

            var name: String {
              switch self {
              case .home:
                "home"
              case .profile:
                "profile"
              }
            }

            var hideTabBarOnPush: Bool {
              true
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func markerOnMultiElementCase_appliesToEveryElement() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case a, b
          case c
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a, b
            case c

            var name: String {
              switch self {
              case .a:
                "a"
              case .b:
                "b"
              case .c:
                "c"
              }
            }

            var hideTabBarOnPush: Bool {
              switch self {
              case .a:
                true
              case .b:
                true
              case .c:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func markerOnEveryMultiElementCase_expands_toConstantTrue() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case a, b
          @HideTabBarOnPush
          case c, d
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a, b
            case c, d

            var name: String {
              switch self {
              case .a:
                "a"
              case .b:
                "b"
              case .c:
                "c"
              case .d:
                "d"
              }
            }

            var hideTabBarOnPush: Bool {
              true
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func markerOnAssociatedValueCase_expands_withWildcardPattern() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case detail(id: Int, flag: Bool)
          case home
        }
        """,
        expandedSource: """
          enum HomeTab {
            case detail(id: Int, flag: Bool)
            case home

            var name: String {
              switch self {
              case .detail(_, _):
                "detail"
              case .home:
                "home"
              }
            }

            var hideTabBarOnPush: Bool {
              switch self {
              case .detail(_, _):
                true
              case .home:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func markerWithRouteName_expands_bothTemplateNameAndHideTabBarOnPush() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          @RouteName(#"Home"#)
          case home
          case profile
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home
            case profile

            var name: String {
              switch self {
              case .home:
                "Home"
              case .profile:
                "profile"
              }
            }

            var hideTabBarOnPush: Bool {
              switch self {
              case .home:
                true
              case .profile:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func publicEnum_expands_publicHideTabBarOnPush() {
      assertExpansion(
        """
        @TabRoutable
        public enum HomeTab {
          @HideTabBarOnPush
          case home
          case profile
        }
        """,
        expandedSource: """
          public enum HomeTab {
            case home
            case profile

            public var name: String {
              switch self {
              case .home:
                "home"
              case .profile:
                "profile"
              }
            }

            public var hideTabBarOnPush: Bool {
              switch self {
              case .home:
                true
              case .profile:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func manualHideTabBarOnPushWithoutMarkers_expands_nameOnly() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          case home
          var hideTabBarOnPush: Bool { true }
        }
        """,
        expandedSource: """
          enum HomeTab {
            case home
            var hideTabBarOnPush: Bool { true }

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }

    @Test
    func qualifiedHideTabBarOnPush_expands_toPerCaseSwitch() {
      // The test harness only strips attributes it expands by bare name, so the qualified
      // attribute stays in the expanded source; the generated members are what matter here.
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @SwiftRoutingMacros.HideTabBarOnPush
          case home
          case profile
        }
        """,
        expandedSource: """
          enum HomeTab {
            @SwiftRoutingMacros.HideTabBarOnPush
            case home
            case profile

            var name: String {
              switch self {
              case .home:
                "home"
              case .profile:
                "profile"
              }
            }

            var hideTabBarOnPush: Bool {
              switch self {
              case .home:
                true
              case .profile:
                false
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """
      )
    }
  }

  @Suite("Diagnostics")
  struct Diagnostics {
    @Test
    func unknownIdentifierInTemplate_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum NotificationsRoute {
          @RouteName(#"Notification(\\(idd))"#)
          case detail(id: Int)
        }
        """,
        expandedSource: """
          enum NotificationsRoute {
            case detail(id: Int)

            var name: String {
              switch self {
              case .detail(_):
                "Notification(\\(idd))"
              }
            }
          }

          extension NotificationsRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'idd' is not an associated value of this case. Available: id", line: 3, column: 3)
        ]
      )
    }

    @Test
    func delegateOnZeroAssociatedValues_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum AppRoute {
          @RouteName(.delegate)
          case plain
        }
        """,
        expandedSource: """
          enum AppRoute {
            case plain

            var name: String {
              switch self {
              case .plain:
                "plain"
              }
            }
          }

          extension AppRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName(.delegate)' requires exactly one associated value on this case", line: 3, column: 3)
        ]
      )
    }

    @Test
    func delegateOnMultipleAssociatedValues_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum AppRoute {
          @RouteName(.delegate)
          case pair(Int, String)
        }
        """,
        expandedSource: """
          enum AppRoute {
            case pair(Int, String)

            var name: String {
              switch self {
              case .pair(_, _):
                "pair"
              }
            }
          }

          extension AppRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName(.delegate)' requires exactly one associated value on this case", line: 3, column: 3)
        ]
      )
    }

    @Test
    func nonStringNonDelegateArgument_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum AppRoute {
          @RouteName(42)
          case x
        }
        """,
        expandedSource: """
          enum AppRoute {
            case x

            var name: String {
              switch self {
              case .x:
                "x"
              }
            }
          }

          extension AppRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName' expects a raw string literal (`#\"...\"#`) or `.delegate`", line: 3, column: 14)
        ]
      )
    }

    @Test
    func nonLiteralNameStyle_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable(nameStyle: style)
        enum AppRoute {
          case home
        }
        """,
        expandedSource: """
          enum AppRoute {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension AppRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'nameStyle' must be a literal `.verbatim` or `.capitalized`", line: 1, column: 25)
        ]
      )
    }

    @Test
    func appliedToStruct_emits_notAnEnumDiagnostic() {
      assertExpansion(
        """
        @TabRoutable
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@TabRoutable' can only be applied to an enum", line: 1, column: 1)
        ]
      )
    }

    @Test
    func routeNameOnMultiElementCase_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum AppRoute {
          @RouteName(#"X"#)
          case a, b
        }
        """,
        expandedSource: """
          enum AppRoute {
            case a, b

            var name: String {
              switch self {
              case .a:
                "a"
              case .b:
                "b"
              }
            }
          }

          extension AppRoute: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName' cannot be applied to a case declaration with multiple elements (`case a, b`) -- split them into separate cases", line: 3, column: 3)
        ]
      )
    }

    @Test
    func hideTabBarOnPushOnNonCase_emits_notACaseDiagnostic() {
      assertExpansion(
        """
        @HideTabBarOnPush
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' can only be applied to an enum case", line: 1, column: 1),
        ]
      )
    }

    @Test
    func hideTabBarOnPushInPlainEnum_emits_outsideTabRoutableDiagnostic() {
      assertExpansion(
        """
        enum Plain {
          @HideTabBarOnPush
          case a
        }
        """,
        expandedSource: """
          enum Plain {
            case a
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum", line: 2, column: 3),
        ]
      )
    }

    @Test
    func hideTabBarOnPushInRoutableEnum_emits_outsideTabRoutableDiagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @HideTabBarOnPush
          case a
        }
        """,
        expandedSource: """
          enum AppRoute {
            case a

            var name: String {
              switch self {
              case .a:
                "a"
              }
            }
          }

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum", line: 3, column: 3),
        ]
      )
    }

    @Test
    func hideTabBarOnPushInNestedPlainEnum_emits_outsideTabRoutableDiagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum Tabs {
          case home
          enum Inner {
            @HideTabBarOnPush
            case a
          }
        }
        """,
        expandedSource: """
          enum Tabs {
            case home
            enum Inner {
              case a
            }

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension Tabs: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum", line: 5, column: 5),
        ]
      )
    }

    @Test
    func markerWithManualHideTabBarOnPush_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case a
          case b
          var hideTabBarOnPush: Bool { true }
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a
            case b
            var hideTabBarOnPush: Bool { true }

            var name: String {
              switch self {
              case .a:
                "a"
              case .b:
                "b"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' cannot be combined with a hand-written 'hideTabBarOnPush' -- remove the marker or the property", line: 3, column: 3),
        ]
      )
    }

    @Test
    func duplicateHideTabBarOnPush_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          @HideTabBarOnPush
          case a
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a

            var name: String {
              switch self {
              case .a:
                "a"
              }
            }

            var hideTabBarOnPush: Bool {
              true
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' is applied more than once to this case", line: 4, column: 3),
        ]
      )
    }

    @Test
    func sheetInTabRoutable_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @Sheet
          case a
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a

            var name: String {
              switch self {
              case .a:
                "a"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Sheet' cannot be used in a '@TabRoutable' enum -- a tab is selected, never presented", line: 3, column: 3),
        ]
      )
    }

    @Test
    func coverInTabRoutable_emits_diagnostic() {
      assertExpansion(
        """
        @TabRoutable
        enum HomeTab {
          @Cover
          case a
        }
        """,
        expandedSource: """
          enum HomeTab {
            case a

            var name: String {
              switch self {
              case .a:
                "a"
              }
            }
          }

          extension HomeTab: TabRoute {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Cover' cannot be used in a '@TabRoutable' enum -- a tab is selected, never presented", line: 3, column: 3),
        ]
      )
    }

    @Test
    func hideTabBarOnPushInQualifiedTabRoutableEnum_emits_noDiagnostic() {
      // The harness doesn't expand the qualified `@SwiftRoutingMacros.TabRoutable`, so this
      // exercises the peer alone: it must recognise the qualified attribute on the enum.
      assertExpansion(
        """
        @SwiftRoutingMacros.TabRoutable
        enum HomeTab {
          @HideTabBarOnPush
          case home
        }
        """,
        expandedSource: """
          @SwiftRoutingMacros.TabRoutable
          enum HomeTab {
            case home
          }
          """
      )
    }

    @Test
    func hideTabBarOnPushInTabRouteAndRoutableEnum_emits_outsideTabRoutableDiagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppTab: TabRoute {
          @HideTabBarOnPush
          case a
        }
        """,
        expandedSource: """
          enum AppTab: TabRoute {
            case a

            var name: String {
              switch self {
              case .a:
                "a"
              }
            }
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum", line: 3, column: 3)
        ],
        conformances: []
      )
    }
  }
}
