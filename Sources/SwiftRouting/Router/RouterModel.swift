//
//  RouterModel.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public protocol RouterModel: ObservableObject {
  func route(to destination: some Route, type: RoutingType)
}
