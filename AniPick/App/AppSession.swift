//
//  AppSession.swift
//  AniPick
//
//  앱 전체가 함께 쓰는 인증 세션. 토큰 갱신과 로그아웃 알림은 여기 한 곳에서만 일어난다.
//

import Foundation
import Networking
import Session

enum AppSession {
    static let shared = AuthSession(
        tokenStore: UserDefaultsManager.shared.tokenStore,
        refresher: HTTPTokenRefresher(
            // 상수 문자열이라 실패하지 않는다.
            client: HTTPClient(baseURL: URL(string: NetworkManager.baseUrl)!, tokenProvider: nil)
        )
    )
}
