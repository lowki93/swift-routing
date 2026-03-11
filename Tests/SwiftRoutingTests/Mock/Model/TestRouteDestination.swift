import SwiftUI
import SwiftRouting

enum TestRouteDestination: RouteDestination {
  static func view(for route: TestRoute) -> some View {
    EmptyView()
  }
}
