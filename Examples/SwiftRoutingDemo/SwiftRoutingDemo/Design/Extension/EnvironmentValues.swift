//
//  EnvironmentValues.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 24/06/2026.
//

import SwiftUI

extension EnvironmentValues {
  @Entry var isSplitThreeColumn: Binding<Bool> = .constant(false)
  @Entry var columnVisibility: Binding<ColumnVisibility> = .constant(.all)
  @Entry var preferredCompactColumn: Binding<NavigationSplitViewColumn> = .constant(.sidebar)
}
