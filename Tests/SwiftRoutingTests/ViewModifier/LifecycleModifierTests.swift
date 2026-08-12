import Foundation
import Testing
@testable import SwiftRouting

struct LifecycleModifierTests {

  struct InitialLog {
    @Test
    func noPreviousLog_shouldLog_return_true() {
      let result = LifecycleModifier.shouldLog(lastDateLog: nil, currentDate: .now)

      #expect(result)
    }
  }

  struct DebounceThreshold {
    @Test
    func elapsedUnder50ms_shouldLog_return_false() {
      let lastDateLog = Date.now
      let currentDate = lastDateLog.addingTimeInterval(0.049)

      let result = LifecycleModifier.shouldLog(lastDateLog: lastDateLog, currentDate: currentDate)

      #expect(result == false)
    }

    @Test
    func elapsedAtLeast50ms_shouldLog_return_true() {
      let lastDateLog = Date.now
      let currentDate = lastDateLog.addingTimeInterval(0.06)

      let result = LifecycleModifier.shouldLog(lastDateLog: lastDateLog, currentDate: currentDate)

      #expect(result)
    }
  }

  struct DuplicateSuppression {
    @Test
    func calledAgainImmediately_shouldLog_return_false() {
      let lastDateLog = Date.now
      let currentDate = lastDateLog.addingTimeInterval(0.001)

      let result = LifecycleModifier.shouldLog(lastDateLog: lastDateLog, currentDate: currentDate)

      #expect(result == false)
    }
  }
}
