//
//  AnalyticsManager.swift
//  AniPick
//
//  Created by cho on 4/12/26.
//

import FirebaseAnalytics
import FirebaseCrashlytics

enum AnalyticsManager {

    // MARK: - 애니 상세
    static func logAnimeDetailView(animeId: Int, animeTitle: String?) {
        Analytics.logEvent("anime_detail_view", parameters: [
            "anime_id": animeId,
            "anime_title": animeTitle ?? ""
        ])
    }

    static func logAnimeLike(animeId: Int, animeTitle: String?) {
        Analytics.logEvent("anime_like", parameters: [
            "anime_id": animeId,
            "anime_title": animeTitle ?? ""
        ])
    }

    static func logAnimeUnlike(animeId: Int, animeTitle: String?) {
        Analytics.logEvent("anime_unlike", parameters: [
            "anime_id": animeId,
            "anime_title": animeTitle ?? ""
        ])
    }

    static func logAnimeShare(animeId: Int, animeTitle: String?) {
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterItemID: "\(animeId)",
            AnalyticsParameterItemName: animeTitle ?? "",
            AnalyticsParameterContentType: "anime"
        ])
    }

    // MARK: - 리뷰
    static func logReviewWrite(animeId: Int, rating: Double, isSpoiler: Bool) {
        Analytics.logEvent("review_write", parameters: [
            "anime_id": animeId,
            "rating": rating,
            "is_spoiler": isSpoiler ? 1 : 0
        ])
    }

    // MARK: - 검색
    static func logSearch(query: String) {
        Analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query
        ])
    }

    // MARK: - 로그인 / 회원가입
    static func logLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logSignUp() {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: "email"
        ])
    }

    // MARK: - 에러 (Crashlytics)
    static func logError(_ error: Error, context: String) {
        Crashlytics.crashlytics().log("[\(context)] \(error.localizedDescription)")
        Crashlytics.crashlytics().record(error: error)
        Analytics.logEvent("api_error", parameters: [
            "context": context,
            "message": error.localizedDescription
        ])
    }

    // MARK: - 로그인 이슈 (에러 객체 없는 논리적 실패도 Crashlytics로 리포팅)
    static func logLoginIssue(provider: String, reason: String) {
        Crashlytics.crashlytics().log("[Login][\(provider)] \(reason)")
        // 비치명적 이벤트로 기록하여 Crashlytics 대시보드에서 조회 가능하게 함
        let error = NSError(
            domain: "LoginIssue",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: reason,
                "provider": provider
            ]
        )
        Crashlytics.crashlytics().record(error: error)
        Analytics.logEvent("login_issue", parameters: [
            "provider": provider,
            "reason": reason
        ])
    }
}
