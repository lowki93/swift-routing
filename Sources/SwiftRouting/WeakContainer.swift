//
//  WeakContainer.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 13/02/2025.
//

import Foundation

struct WeakContainer<T: AnyObject> {
  weak var value: T?
}
