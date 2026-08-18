//
//  ChoiceReset.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

/// Signal-only context: tapping "Back to choice" in Settings asks ChoiceScreen to
/// deselect the current navigation paradigm and return to the picker. Carries no
/// payload -- it exists purely to drive `terminate()` up to the app-level router.
struct ChoiceReset: RouteContext {}
