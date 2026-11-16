//
//  AnalyticsManager.swift
//  AniPick
//
//  Created by cho on 4/12/26.
//

import Analytics

/// 레거시 화면이 쓰는 분석 이벤트 함수. 이벤트 정의와 Firebase 전송은 Analytics·AnalyticsLive 모듈이 맡는다.
/// 각 화면을 이관하면 호출부가 `AnalyticsTracking`을 직접 쓰게 된다.
enum AnalyticsManager {

    // MARK: - 사용자 식별 (Crashlytics·Analytics 공통)
    // 서버 내부 userId만 쓴다. 이메일·닉네임 같은 개인정보는 넣지 않는다.
    static func setUser(userId: Int?, loginMethod: String) {
        AppAnalytics.tracker.setUser(id: userId.map(String.init), loginMethod: loginMethod)
    }

    static func clearUser() {
        AppAnalytics.tracker.setUser(id: nil, loginMethod: nil)
    }

    // 앱 실행 시 이미 로그인된 사용자의 식별 정보를 다시 붙인다
    static func restoreUser() {
        let defaults = UserDefaultsManager.shared
        guard !defaults.getAccessToken().isEmpty else { return }
        let sns = defaults.getSNSAccount()
        setUser(userId: defaults.getUserId(), loginMethod: sns.isEmpty ? "email" : sns)
    }

    // MARK: - 화면 조회
    static func logScreen(_ name: String) {
        AppAnalytics.tracker.logScreen(name)
    }

    // MARK: - 온보딩 (취향 선택)
    static func logOnboardingComplete(ratedCount: Int) {
        AppAnalytics.tracker.log(.onboardingComplete(ratedCount: ratedCount))
    }

    // MARK: - 애니 상세
    static func logAnimeDetailView(animeId: Int, animeTitle: String?) {
        AppAnalytics.tracker.log(.animeDetailView(animeId: animeId, animeTitle: animeTitle))
    }

    static func logAnimeLike(animeId: Int, animeTitle: String?) {
        AppAnalytics.tracker.log(.animeLike(animeId: animeId, animeTitle: animeTitle))
    }

    static func logAnimeUnlike(animeId: Int, animeTitle: String?) {
        AppAnalytics.tracker.log(.animeUnlike(animeId: animeId, animeTitle: animeTitle))
    }

    static func logAnimeShare(animeId: Int, animeTitle: String?) {
        AppAnalytics.tracker.log(.animeShare(animeId: animeId, animeTitle: animeTitle))
    }

    // MARK: - 리뷰
    static func logReviewWrite(animeId: Int, rating: Double, isSpoiler: Bool) {
        AppAnalytics.tracker.log(.reviewWrite(animeId: animeId, rating: rating, isSpoiler: isSpoiler))
    }

    // MARK: - 검색
    static func logSearch(query: String) {
        AppAnalytics.tracker.log(.search(query: query))
    }

    // MARK: - 로그인 / 회원가입
    static func logLogin(method: String) {
        AppAnalytics.tracker.log(.login(method: method))
    }

    static func logSignUp() {
        AppAnalytics.tracker.log(.signUp)
    }

    // MARK: - 에러 (Crashlytics)
    static func logError(_ error: Error, context: String) {
        AppAnalytics.tracker.logError(error, context: context)
    }

    // MARK: - 로그인 이슈 (에러 객체 없는 논리적 실패도 Crashlytics로 리포팅)
    static func logLoginIssue(provider: String, reason: String) {
        AppAnalytics.tracker.logLoginIssue(provider: provider, reason: reason)
    }
}
