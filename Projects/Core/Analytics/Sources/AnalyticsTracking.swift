import Foundation

/// 분석 이벤트와 비치명 오류를 보내는 곳. Firebase 구현은 AnalyticsLive에 있다.
public protocol AnalyticsTracking: Sendable {
    func log(_ event: AnalyticsEvent)
    /// 비치명 오류 기록. `breadcrumb`는 오류 직전에 남기는 로그 한 줄
    func recordNonFatal(_ error: any Error, breadcrumb: String)
}

extension AnalyticsTracking {
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
