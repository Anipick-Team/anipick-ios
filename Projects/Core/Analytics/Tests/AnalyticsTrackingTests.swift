import Foundation
import Testing
import os

@testable import Analytics

/// 보낸 이벤트와 비치명 오류를 기록한다
final class RecordingTracker: AnalyticsTracking {
    struct User: Equatable {
        let id: String?
        let loginMethod: String?
    }

    struct NonFatal {
        let error: NSError
        let breadcrumb: String
    }

    private let state = OSAllocatedUnfairLock(
        uncheckedState: (
            events: [AnalyticsEvent](),
            nonFatals: [NonFatal](),
            users: [User](),
            screens: [String]()
        )
    )

    var events: [AnalyticsEvent] {
        return state.withLockUnchecked { $0.events }
    }

    var nonFatals: [NonFatal] {
        return state.withLockUnchecked { $0.nonFatals }
    }

    var users: [User] {
        return state.withLockUnchecked { $0.users }
    }

    var screens: [String] {
        return state.withLockUnchecked { $0.screens }
    }

    func log(_ event: AnalyticsEvent) {
        state.withLockUnchecked { $0.events.append(event) }
    }

    func recordNonFatal(_ error: any Error, breadcrumb: String) {
        state.withLockUnchecked {
            $0.nonFatals.append(NonFatal(error: error as NSError, breadcrumb: breadcrumb))
        }
    }

    func setUser(id: String?, loginMethod: String?) {
        state.withLockUnchecked { $0.users.append(User(id: id, loginMethod: loginMethod)) }
    }

    func markScreen(_ name: String) {
        state.withLockUnchecked { $0.screens.append(name) }
    }
}

private struct SampleError: LocalizedError {
    var errorDescription: String? {
        return "서버 오류"
    }
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

    @Test("logScreen은 screen_view 이벤트를 보내고 오류 리포트에 화면 이름을 남긴다")
    func logsScreen() {
        let tracker = RecordingTracker()

        tracker.logScreen("setting")

        #expect(tracker.events == [.screenView(name: "setting")])
        #expect(tracker.screens == ["setting"])
    }
}
