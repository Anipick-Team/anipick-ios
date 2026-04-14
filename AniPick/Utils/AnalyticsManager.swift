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
}
