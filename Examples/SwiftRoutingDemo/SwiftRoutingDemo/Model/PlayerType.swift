//
//  PlayerType.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import Foundation

enum PlayerType: String, Identifiable {
  case footballer
  case basketballPlayer

  var id: String {
    rawValue
  }
}
