//
//  AppAnalytics.swift
//  AniPick
//
//  앱 전체가 함께 쓰는 분석 이벤트 전송기. Firebase는 AnalyticsLive 모듈 안에서만 쓴다.
//

import Analytics
import AnalyticsLive

enum AppAnalytics {
    static let tracker: any AnalyticsTracking = FirebaseAnalyticsTracker()
}
