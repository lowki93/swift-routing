import Testing
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
@testable import SwiftRoutingMacrosPlugin

func assertExpansion(
  _ originalSource: String,
  expandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  conformances: [TypeSyntax]? = nil,
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
      "Routable": MacroSpec(type: RoutableMacro.self, conformances: conformances ?? ["Route"]),
      "TabRoutable": MacroSpec(type: TabRoutableMacro.self, conformances: conformances ?? ["TabRoute"]),
      "RouteName": MacroSpec(type: RouteNameMacro.self),
      "Sheet": MacroSpec(type: SheetMacro.self),
      "Cover": MacroSpec(type: CoverMacro.self),
      "HideTabBarOnPush": MacroSpec(type: HideTabBarOnPushMacro.self),
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
