import Foundation

/// 분석 이벤트와 비치명 오류를 보내는 곳. Firebase 구현은 AnalyticsLive에 있다.
public protocol AnalyticsTracking: Sendable {
    func log(_ event: AnalyticsEvent)
    /// 비치명 오류 기록. `breadcrumb`는 오류 직전에 남기는 로그 한 줄
    func recordNonFatal(_ error: any Error, breadcrumb: String)
    /// 사용자 식별. 서버 내부 userId만 넣는다 — 이메일·닉네임 같은 개인정보는 넣지 않는다. 둘 다 nil이면 지운다
    func setUser(id: String?, loginMethod: String?)
    /// 크래시 직전 화면을 알 수 있게 오류 리포트에 화면 이름을 남긴다
    func markScreen(_ name: String)
}

extension AnalyticsTracking {
    /// 화면 조회 기록 (레거시 `AnalyticsManager.logScreen`). SwiftUI 화면은 자동 수집이 부정확해 직접 기록한다
    public func logScreen(_ name: String) {
        log(.screenView(name: name))
        markScreen(name)
    }

    /// 요청 실패 기록 (레거시 `AnalyticsManager.logError`)
    public func logError(_ error: any Error, context: String) {
        let message = error.localizedDescription
        recordNonFatal(error, breadcrumb: "[\(context)] \(message)")
        log(.apiError(context: context, message: message))
    }

    /// 오류 객체 없는 로그인 실패 기록 (레거시 `AnalyticsManager.logLoginIssue`)
    public func logLoginIssue(provider: String, reason: String) {
        let error = NSError(
            domain: "LoginIssue",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: reason,
                "provider": provider,
            ]
        )
        recordNonFatal(error, breadcrumb: "[Login][\(provider)] \(reason)")
        log(.loginIssue(provider: provider, reason: reason))
    }
}
