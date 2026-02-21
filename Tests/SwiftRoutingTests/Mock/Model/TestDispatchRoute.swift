import SwiftRouting

enum TestDispatchRoute: Route {
  case pushed
  case rooted
  case covered
  case sheetWithStack
  case sheetWithoutStack

  var name: String {
    switch self {
    case .pushed: "pushed"
    case .rooted: "rooted"
    case .covered: "covered"
    case .sheetWithStack: "sheetWithStack"
    case .sheetWithoutStack: "sheetWithoutStack"
    }
  }

  var routingType: RoutingType {
    switch self {
    case .pushed: .push
    case .rooted: .root
    case .covered: .cover
    case .sheetWithStack: .sheet(withStack: true)
    case .sheetWithoutStack: .sheet(withStack: false)
    }
  }
}
