//
//  RouterModel.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public protocol RouterModel: ObservableObject {
  associatedtype R: Route

  var routeTo: (type: RoutingType, route: R)? { get set }
}
