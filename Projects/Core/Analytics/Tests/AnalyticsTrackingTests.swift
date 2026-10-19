import Foundation
import Testing
import os

@testable import Analytics

/// 보낸 이벤트와 비치명 오류를 기록한다
final class RecordingTracker: AnalyticsTracking {
    struct NonFatal {
        let error: NSError
        let breadcrumb: String
    }

    private let state = OSAllocatedUnfairLock(
        uncheckedState: (events: [AnalyticsEvent](), nonFatals: [NonFatal]())
    )

    var events: [AnalyticsEvent] {
        return state.withLockUnchecked { $0.events }
    }

    var nonFatals: [NonFatal] {
        return state.withLockUnchecked { $0.nonFatals }
    }

    func log(_ event: AnalyticsEvent) {
        state.withLockUnchecked { $0.events.append(event) }
    }

    func recordNonFatal(_ error: any Error, breadcrumb: String) {
        state.withLockUnchecked {
            $0.nonFatals.append(NonFatal(error: error as NSError, breadcrumb: breadcrumb))
        }
    }
}

private struct SampleError: LocalizedError {
    var errorDescription: String? { "서버 오류" }
}

@Suite("AnalyticsTracking 조합")
struct AnalyticsTrackingTests {
    @Test("logError는 Crashlytics 기록 후 api_error 이벤트를 보낸다")
    func logsError() throws {
        let tracker = RecordingTracker()

        tracker.logError(SampleError(), context: "fetchAnimationInfo")

        let nonFatal = try #require(tracker.nonFatals.first)
        #expect(tracker.nonFatals.count == 1)
        #expect(nonFatal.breadcrumb == "[fetchAnimationInfo] 서버 오류")
        #expect(tracker.events == [.apiError(context: "fetchAnimationInfo", message: "서버 오류")])
    }

    @Test("logLoginIssue는 LoginIssue NSError를 기록한 뒤 login_issue 이벤트를 보낸다")
    func logsLoginIssue() throws {
        let tracker = RecordingTracker()

        tracker.logLoginIssue(provider: "google", reason: "idToken nil")

        let nonFatal = try #require(tracker.nonFatals.first)
        #expect(nonFatal.breadcrumb == "[Login][google] idToken nil")
        #expect(nonFatal.error.domain == "LoginIssue")
        #expect(nonFatal.error.code == 0)
        #expect(nonFatal.error.localizedDescription == "idToken nil")
        #expect(nonFatal.error.userInfo["provider"] as? String == "google")
        #expect(tracker.events == [.loginIssue(provider: "google", reason: "idToken nil")])
    }
}
