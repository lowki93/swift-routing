//
//  RouterModel.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public protocol RouterModel: ObservableObject {
  func push(_ destination: some Route)
  func present(_ destination: some Route)
  func cover(_ destination: some Route)
}
