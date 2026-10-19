//
//  SessionState.swift
//  AniPick
//
//  Session 이벤트를 받아 루트 화면을 바꾼다. 로그아웃 화면 전환은 여기 한 곳에서만 일어난다.
//

import Session

@MainActor
final class SessionState {
    private let navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    /// 스트림이 끝날 때까지 로그아웃 이벤트마다 로그인 화면으로 돌아간다.
    func observe(_ events: AsyncStream<SessionEvent>) async {
        for await event in events {
            switch event {
            case .signedOut(let reason):
                DLog("🔐 [Login] Session 로그아웃(\(reason)) - completeLogout")
                navigationManager.completeLogout()
            }
        }
    }
}
