import Testing
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
@testable import SwiftRoutingMacrosPlugin

private func assertExpansion(
  _ originalSource: String,
  expandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  conformances: [TypeSyntax] = ["Route"],
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  assertMacroExpansion(
    originalSource,
    expandedSource: expandedSource,
    diagnostics: diagnostics,
    macroSpecs: [
      "Routable": MacroSpec(type: RoutableMacro.self, conformances: conformances),
      "RouteName": MacroSpec(type: RouteNameMacro.self),
    ],
    indentationWidth: .spaces(2),
    failureHandler: { spec in
      Issue.record(
        Comment(rawValue: spec.message),
        sourceLocation: SourceLocation(
          fileID: spec.location.fileID,
          filePath: spec.location.filePath,
          line: spec.location.line,
          column: spec.location.column
        )
      )
    },
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@Suite("RoutableMacro expansion")
struct RoutableMacroExpansionTests {

  @Suite("Players (positional associated values + member access)")
  struct Players {
    @Test
    func positionalTemplate_expands_toSwitchWithArgBindings() {
      assertExpansion(
        """
        @Routable
        enum PlayersRoute {
          @RouteName(#"Players(\\(arg0))"#)
          case list(PlayerType)
          @RouteName(#"Player(\\(arg0.name))"#)
          case detail(Player)
        }
        """,
        expandedSource: """
          enum PlayersRoute {
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

          extension PlayersRoute: Route {
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
        @Routable
        enum FormRoute {
          @RouteName(#"FormFlow"#)
          case flow
          @RouteName(#"Form"#)
          case entry
        }
        """,
        expandedSource: """
          enum FormRoute {
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

          extension FormRoute: Route {
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
        @Routable
        enum NotificationsRoute {
          @RouteName(#"Notifications"#)
          case list
          @RouteName(#"Notification(\\(id))"#)
          case detail(id: Int)
        }
        """,
        expandedSource: """
          enum NotificationsRoute {
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

          extension NotificationsRoute: Route {
          }
          """
      )
    }

    @Test
    func delegateCase_expands_toChildNameComposition() {
      assertExpansion(
        """
        @Routable(nameStyle: .capitalized)
        enum AppRoute {
          @RouteName(.delegate)
          case notifications(NotificationsRoute)
        }
        """,
        expandedSource: """
          enum AppRoute {
            case notifications(NotificationsRoute)

            var name: String {
              switch self {
              case .notifications(let arg0):
                "Notifications.\\(arg0.name)"
              }
            }
          }

          extension AppRoute: Route {
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
        @Routable(nameStyle: .capitalized)
        enum AppRoute {
          case profile
          case search
        }
        """,
        expandedSource: """
          enum AppRoute {
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

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func verbatimStyle_simpleCase_expands_verbatim() {
      assertExpansion(
        """
        @Routable
        enum HomeRoute {
          case home
        }
        """,
        expandedSource: """
          enum HomeRoute {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeRoute: Route {
          }
          """
      )
    }
  }

  @Suite("Route conformance")
  struct Conformance {
    @Test
    func enumWithoutExplicitRouteConformance_expands_extensionAddingRoute() {
      assertExpansion(
        """
        @Routable
        enum HomeRoute {
          case home
        }
        """,
        expandedSource: """
          enum HomeRoute {
            case home

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension HomeRoute: Route {
          }
          """,
        conformances: ["Route"]
      )
    }

    @Test
    func enumWithExplicitRouteConformance_expands_noRedundantExtension() {
      assertExpansion(
        """
        @Routable
        enum HomeRoute: Route {
          case home
        }
        """,
        expandedSource: """
          enum HomeRoute: Route {
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
  }

  @Suite("Diagnostics")
  struct Diagnostics {
    @Test
    func unknownIdentifierInTemplate_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
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

          extension NotificationsRoute: Route {
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
        @Routable
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

          extension AppRoute: Route {
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
        @Routable
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

          extension AppRoute: Route {
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
        @Routable
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

          extension AppRoute: Route {
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
        @Routable(nameStyle: style)
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

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'nameStyle' must be a literal `.verbatim` or `.capitalized`", line: 1, column: 22)
        ]
      )
    }

    @Test
    func appliedToStruct_emits_notAnEnumDiagnostic() {
      assertExpansion(
        """
        @Routable
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Routable' can only be applied to an enum", line: 1, column: 1)
        ]
      )
    }

    @Test
    func routeNameOnMultiElementCase_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
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

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName' cannot be applied to a case declaration with multiple elements (`case a, b`) -- split them into separate cases", line: 3, column: 3)
        ]
      )
    }
  }
}
