//
//  LegacyNavigator.swift
//  AniPick
//
//  새 Feature가 요청한 이동을 레거시 NavigationManager 경로에 반영한다.
//  레거시 화면과 새 화면이 한 스택을 공유하는 동안(이관 Phase 3)만 쓴다.
//

import SwiftUI
import Navigation

/// 모달로 띄운 Route. 같은 Route를 다시 띄워도 새 표시로 인식되게 id를 따로 둔다.
struct PresentedRoute: Identifiable {
    let id = UUID()
    let route: AnyHashable
}

@MainActor
final class LegacyNavigator: Navigator {
    private let navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    func push(_ route: some Hashable & Sendable) {
        navigationManager.path.append(route)
    }

    func pop() {
        // 레거시 NavigationManager.pop()은 빈 경로에서 크래시한다
        guard !navigationManager.path.isEmpty else {
            return
        }
        navigationManager.path.removeLast()
    }

    func popToRoot() {
        navigationManager.path = NavigationPath()
    }

    func present(_ route: some Hashable & Sendable) {
        navigationManager.presentedRoute = PresentedRoute(route: AnyHashable(route))
    }

    func dismiss() {
        navigationManager.presentedRoute = nil
    }
}
