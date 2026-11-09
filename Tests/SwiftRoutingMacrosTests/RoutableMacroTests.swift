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
      "Sheet": MacroSpec(type: SheetMacro.self),
      "Cover": MacroSpec(type: CoverMacro.self),
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

  @Suite("routingType")
  struct RoutingTypeTests {
    @Test
    func sheetAndCoverMarkers_expand_toRoutingTypeSwitch() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          case home
          @Sheet(withStack: true)
          case settings
          @Cover
          case onboarding
          case order(id: String)
        }
        """,
        expandedSource: """
          enum AppRoute {
            case home
            case settings
            case onboarding
            case order(id: String)

            var name: String {
              switch self {
              case .home:
                "home"
              case .settings:
                "settings"
              case .onboarding:
                "onboarding"
              case .order(_):
                "order"
              }
            }

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .home:
                .push
              case .settings:
                .sheet(withStack: true)
              case .onboarding:
                .cover
              case .order(_):
                .push
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func bareSheet_expands_toSheetWithStackTrue() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet
          case a
          @Sheet()
          case b
        }
        """,
        expandedSource: """
          enum AppRoute {
            case a
            case b

            var name: String {
              switch self {
              case .a:
                "a"
              case .b:
                "b"
              }
            }

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .a:
                .sheet(withStack: true)
              case .b:
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func sheetWithStackFalse_expands_toSheetWithStackFalse() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet(withStack: false)
          case filters
        }
        """,
        expandedSource: """
          enum AppRoute {
            case filters

            var name: String {
              switch self {
              case .filters:
                "filters"
              }
            }

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .filters:
                .sheet(withStack: false)
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func markerOnAssociatedValueCases_expands_withWildcardPatterns() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Cover
          case order(id: String)
          @Sheet
          case pair(Int, Int)
        }
        """,
        expandedSource: """
          enum AppRoute {
            case order(id: String)
            case pair(Int, Int)

            var name: String {
              switch self {
              case .order(_):
                "order"
              case .pair(_, _):
                "pair"
              }
            }

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .order(_):
                .cover
              case .pair(_, _):
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func markerWithDelegate_expands_bothDelegatedNameAndRoutingType() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet
          @RouteName(.delegate)
          case form(FormRoute)
        }
        """,
        expandedSource: """
          enum AppRoute {
            case form(FormRoute)

            var name: String {
              switch self {
              case .form(let arg0):
                "form.\\(arg0.name)"
              }
            }

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .form(_):
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func publicEnum_expands_publicRoutingType() {
      assertExpansion(
        """
        @Routable
        public enum AppRoute {
          @Cover
          case onboarding
        }
        """,
        expandedSource: """
          public enum AppRoute {
            case onboarding

            public var name: String {
              switch self {
              case .onboarding:
                "onboarding"
              }
            }

            public var routingType: SwiftRouting.RoutingType {
              switch self {
              case .onboarding:
                .cover
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func markerOnMultiElementCase_appliesToEveryElement() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Cover
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

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .a:
                .cover
              case .b:
                .cover
              }
            }
          }

          extension AppRoute: Route {
          }
          """
      )
    }

    @Test
    func manualRoutingTypeWithoutMarkers_expands_nameOnly() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          case home
          var routingType: RoutingType { .push }
        }
        """,
        expandedSource: """
          enum AppRoute {
            case home
            var routingType: RoutingType { .push }

            var name: String {
              switch self {
              case .home:
                "home"
              }
            }
          }

          extension AppRoute: Route {
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

    @Test
    func sheetAndCoverOnSameCase_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet
          @Cover
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

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .a:
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Cover' conflicts with '@Sheet' on the same case -- a case can have only one routing type marker", line: 4, column: 3)
        ]
      )
    }

    @Test
    func duplicateSheetMarkers_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet
          @Sheet(withStack: false)
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

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .a:
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Sheet' is applied more than once to this case", line: 4, column: 3)
        ]
      )
    }

    @Test
    func nonLiteralWithStack_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet(withStack: flag)
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

            var routingType: SwiftRouting.RoutingType {
              switch self {
              case .a:
                .sheet(withStack: true)
              }
            }
          }

          extension AppRoute: Route {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'withStack' must be a literal `true` or `false`", line: 3, column: 21)
        ]
      )
    }

    @Test
    func markersWithManualRoutingType_emits_diagnostic() {
      assertExpansion(
        """
        @Routable
        enum AppRoute {
          @Sheet
          case a
          @Cover
          case b
          var routingType: RoutingType { .push }
        }
        """,
        expandedSource: """
          enum AppRoute {
            case a
            case b
            var routingType: RoutingType { .push }

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
          DiagnosticSpec(message: "'@Sheet' cannot be combined with a hand-written 'routingType' -- remove the marker or the property", line: 3, column: 3),
          DiagnosticSpec(message: "'@Cover' cannot be combined with a hand-written 'routingType' -- remove the marker or the property", line: 5, column: 3),
        ]
      )
    }

    @Test
    func sheetOnNonCase_emits_notACaseDiagnostic() {
      assertExpansion(
        """
        @Sheet
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Sheet' can only be applied to an enum case", line: 1, column: 1)
        ]
      )
    }

    @Test
    func coverOnNonCase_emits_notACaseDiagnostic() {
      assertExpansion(
        """
        @Cover
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@Cover' can only be applied to an enum case", line: 1, column: 1)
        ]
      )
    }

    @Test
    func routeNameOnNonCase_emits_notACaseDiagnostic() {
      assertExpansion(
        """
        @RouteName(#"X"#)
        struct S {
        }
        """,
        expandedSource: """
          struct S {
          }
          """,
        diagnostics: [
          DiagnosticSpec(message: "'@RouteName' can only be applied to an enum case", line: 1, column: 1)
        ]
      )
    }
  }
}
