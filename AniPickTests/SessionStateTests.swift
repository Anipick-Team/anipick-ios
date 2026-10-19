//
//  SessionStateTests.swift
//  AniPickTests
//
//  스펙: notes/2026-10-18-T-session-legacy-wiring.md 5절 (S9·S10)
//

import Session
import SwiftUI
import Testing

@testable import AniPick

@MainActor
@Suite("SessionState", .timeLimit(.minutes(1)))
struct SessionStateTests {
    private func loggedInNavigation() -> NavigationManager {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = true
        navigationManager.path.append(AppRoute.setting)
        navigationManager.path.append(AppRoute.logout)
        return navigationManager
    }

    @Test(
        "S9. 로그아웃 이벤트는 이유와 무관하게 로그인 화면으로 돌린다",
        arguments: [SignOutReason.userLogout, .withdrawal, .expired]
    )
    func logsOutOnSignedOut(reason: SignOutReason) async {
        let navigationManager = loggedInNavigation()
        let (events, continuation) = AsyncStream.makeStream(of: SessionEvent.self)
        continuation.yield(.signedOut(reason))
        continuation.finish()

        await SessionState(navigationManager: navigationManager).observe(events)

        #expect(navigationManager.isLoggedIn == false)
        #expect(navigationManager.path.isEmpty)
    }

    @Test("S10. 이벤트가 없으면 화면을 바꾸지 않는다")
    func keepsStateWithoutEvents() async {
        let navigationManager = loggedInNavigation()
        let (events, continuation) = AsyncStream.makeStream(of: SessionEvent.self)
        continuation.finish()

        await SessionState(navigationManager: navigationManager).observe(events)

        #expect(navigationManager.isLoggedIn == true)
        #expect(navigationManager.path.count == 2)
    }
}
