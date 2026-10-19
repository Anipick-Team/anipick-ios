//
//  LegacyNavigatorTests.swift
//  AniPickTests
//
//  설계: notes/2026-10-19-1-8-navigation-design.md 3절
//

import MVICore
import Navigation
import SwiftUI
import Testing

@testable import AniPick

/// Interface 모듈에 둘 새 Route를 흉내 낸다
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
@Suite("LegacyNavigator", .timeLimit(.minutes(1)))
struct LegacyNavigatorTests {
    private let navigationManager = NavigationManager()
    private var navigator: LegacyNavigator {
        return LegacyNavigator(navigationManager: navigationManager)
    }

    @Test("레거시 경로 위에 새 Route를 push하고 pop한다")
    func pushesOntoLegacyPath() {
        navigationManager.path.append(AppRoute.setting)

        navigator.push(NewRoute(id: 1))
        #expect(navigationManager.path.count == 2)

        navigator.pop()
        #expect(navigationManager.path.count == 1)
    }

    @Test("빈 경로에서 pop해도 아무 일도 일어나지 않는다")
    func popOnEmptyPathDoesNothing() {
        navigator.pop()

        #expect(navigationManager.path.isEmpty)
    }

    @Test("popToRoot는 경로를 비운다")
    func popsToRoot() {
        navigationManager.path.append(AppRoute.setting)
        navigator.push(NewRoute(id: 1))

        navigator.popToRoot()

        #expect(navigationManager.path.isEmpty)
    }

    @Test("present는 모달 Route를 설정하고, dismiss는 해제한다")
    func presentsAndDismisses() throws {
        navigator.present(NewRoute(id: 1))
        let first = try #require(navigationManager.presentedRoute)
        #expect(first.route == AnyHashable(NewRoute(id: 1)))

        navigator.dismiss()
        #expect(navigationManager.presentedRoute == nil)

        navigator.present(NewRoute(id: 1))
        let second = try #require(navigationManager.presentedRoute)
        #expect(second.id != first.id)
    }

    @Test("리듀서가 Effect 안에서 요청한 이동이 경로에 반영된다")
    func navigatesFromEffect() async {
        let store = Store(
            initialState: NavigatingReducer.State(),
            reducer: NavigatingReducer(navigator: navigator)
        )

        await store.send(.open(7)).finish()

        #expect(navigationManager.path.count == 1)
    }
}
