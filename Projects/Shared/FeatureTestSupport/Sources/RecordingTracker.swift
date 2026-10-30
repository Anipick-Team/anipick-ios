import Analytics
import Foundation
import os

/// 보낸 분석 이벤트와 비치명 오류를 기록한다
public final class RecordingTracker: AnalyticsTracking {
    public struct NonFatal: Sendable {
        public let error: NSError
        public let breadcrumb: String
    }

    private struct State {
        var events: [AnalyticsEvent] = []
        var nonFatals: [NonFatal] = []
        var screens: [String] = []
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    public nonisolated init() {}

    public var events: [AnalyticsEvent] {
        return state.withLockUnchecked { $0.events }
    }

    public var nonFatals: [NonFatal] {
        return state.withLockUnchecked { $0.nonFatals }
    }

    public var screens: [String] {
        return state.withLockUnchecked { $0.screens }
    }

    public nonisolated func log(_ event: AnalyticsEvent) {
        state.withLockUnchecked { $0.events.append(event) }
    }

    public nonisolated func recordNonFatal(_ error: any Error, breadcrumb: String) {
        state.withLockUnchecked {
            $0.nonFatals.append(NonFatal(error: error as NSError, breadcrumb: breadcrumb))
        }
    }

    public nonisolated func setUser(id: String?, loginMethod: String?) {}

    public nonisolated func markScreen(_ name: String) {
        state.withLockUnchecked { $0.screens.append(name) }
    }
}
