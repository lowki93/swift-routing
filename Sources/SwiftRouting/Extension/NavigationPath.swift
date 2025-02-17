//
//  NavigationPath.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

extension NavigationPath {
  mutating func popToRoot() {
    removeLast(count)
  }
}
