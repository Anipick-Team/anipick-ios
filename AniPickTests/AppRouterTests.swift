//
//  AppRouterTests.swift
//  AniPickTests
//
//  동작 목록: notes/2026-10-30-T-phase4-5-tabs-legacy-removal.md (TB1~TB9)
//  Navigator 부분은 notes/2026-10-19-1-8-navigation-design.md 3절을 이어받는다
//

import MVICore
import Navigation
import SwiftUI
import Testing

@testable import AniPick

/// Interface 모듈의 Route를 흉내 낸다
private struct NewRoute: Hashable, Sendable {
    let id: Int
}

/// Effect 안에서 이동을 요청하는 리듀서
private struct NavigatingReducer: Reducer {
    let navigator: any Navigator

    struct State {}

    enum Intent: Sendable {
        case open(Int)
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .open(let id):
            return .run { [navigator] in
                await navigator.push(NewRoute(id: id))
                return nil
            }
        }
    }
}

@MainActor
@Suite("AppRouter", .timeLimit(.minutes(1)))
struct AppRouterTests {
    private let router = AppRouter(isLoggedIn: true)

    @Test("TB1. push는 지금 탭의 스택에 쌓이고, 탭을 바꿔도 각 탭의 스택은 남는다")
    func stacksPerTab() {
        router.push(NewRoute(id: 1))
        router.select(.myInfo)
        router.push(NewRoute(id: 2))
        router.push(NewRoute(id: 3))

        router.select(.home)

        #expect(router.path(for: .home) == NavigationPath([NewRoute(id: 1)]))
        #expect(router.path(for: .myInfo) == NavigationPath([NewRoute(id: 2), NewRoute(id: 3)]))
        #expect(router.path(for: .ranking).isEmpty)
    }

    @Test("TB3. 지금 탭을 다시 누르면 그 탭의 루트로, 다른 탭을 누르면 탭만 바뀐다")
    func reselectingTabPopsToRoot() {
        router.push(NewRoute(id: 1))
        router.tapTab(.ranking)
        router.push(NewRoute(id: 2))

        router.tapTab(.home)
        #expect(router.selectedTab == .home)
        #expect(router.path(for: .home).count == 1)

        router.tapTab(.home)
        #expect(router.path(for: .home).isEmpty)
        #expect(router.path(for: .ranking).count == 1)
    }

    @Test("TB3. 탭바 바인딩도 같은 규칙을 따른다")
    func tabSelectionBinding() {
        router.push(NewRoute(id: 1))

        router.tabSelection.wrappedValue = .home

        #expect(router.path(for: .home).isEmpty)
    }

    @Test("TB4. 다른 화면이 탭을 고르면 그 탭의 스택은 그대로 둔다")
    func selectKeepsTargetStack() {
        router.select(.research)
        router.push(NewRoute(id: 1))
        router.select(.home)

        router.select(.research)

        #expect(router.selectedTab == .research)
        #expect(router.path(for: .research).count == 1)
    }

    @Test("TB6. 로그인 전에는 로그인 스택에 쌓는다")
    func pushesOntoAuthPathBeforeLogin() {
        let router = AppRouter(isLoggedIn: false)

        router.push(NewRoute(id: 1))

        #expect(router.authPath.count == 1)
        #expect(router.path(for: .home).isEmpty)
    }

    @Test("TB6. 로그인하면 모든 스택을 비우고 홈 탭으로 간다")
    func loginResetsStacks() {
        let router = AppRouter(isLoggedIn: false)
        router.push(NewRoute(id: 1))

        router.completeLogin()

        #expect(router.isLoggedIn)
        #expect(router.authPath.isEmpty)
        #expect(router.selectedTab == .home)
    }

    @Test("TB6. 로그아웃하면 모든 탭 스택을 비우고 로그인 화면으로 간다")
    func logoutResetsStacks() {
        router.push(NewRoute(id: 1))
        router.select(.myInfo)
        router.push(NewRoute(id: 2))
        router.present(NewRoute(id: 3))

        router.completeLogout()

        #expect(router.isLoggedIn == false)
        #expect(Tab.allCases.allSatisfy { router.path(for: $0).isEmpty })
        #expect(router.selectedTab == .home)
        #expect(router.presentedRoute == nil)
    }

    @Test("TB9. pop은 지금 탭에서 하나 빼고, 빈 스택에서는 아무 일도 없다")
    func pops() {
        router.push(NewRoute(id: 1))
        router.select(.ranking)

        router.pop()
        #expect(router.path(for: .home).count == 1)

        router.select(.home)
        router.pop()
        #expect(router.path(for: .home).isEmpty)
    }

    @Test("TB9. popToRoot는 지금 탭의 스택만 비운다")
    func popsToRoot() {
        router.select(.ranking)
        router.push(NewRoute(id: 1))
        router.select(.home)
        router.push(NewRoute(id: 2))
        router.push(NewRoute(id: 3))

        router.popToRoot()

        #expect(router.path(for: .home).isEmpty)
        #expect(router.path(for: .ranking).count == 1)
    }

    @Test("TB9. present는 모달 Route를 설정하고, dismiss는 해제한다")
    func presentsAndDismisses() throws {
        router.present(NewRoute(id: 1))
        let first = try #require(router.presentedRoute)
        #expect(first.route == AnyHashable(NewRoute(id: 1)))

        router.dismiss()
        #expect(router.presentedRoute == nil)

        router.present(NewRoute(id: 1))
        let second = try #require(router.presentedRoute)
        #expect(second.id != first.id)
    }

    @Test("리듀서가 Effect 안에서 요청한 이동이 지금 탭의 스택에 반영된다")
    func navigatesFromEffect() async {
        router.select(.myInfo)
        let store = Store(
            initialState: NavigatingReducer.State(),
            reducer: NavigatingReducer(navigator: router)
        )

        await store.send(.open(7)).finish()

        #expect(router.path(for: .myInfo) == NavigationPath([NewRoute(id: 7)]))
    }
}
