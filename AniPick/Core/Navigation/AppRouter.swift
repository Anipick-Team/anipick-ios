//
//  AppRouter.swift
//  AniPick
//
//  탭마다 내비게이션 스택을 따로 둔다 (Phase 4-2, A4). 로그인 전 화면은 스택 하나를 따로 쓴다.
//  동작 목록: notes/2026-10-30-T-phase4-5-tabs-legacy-removal.md (TB1~TB9)
//

import Navigation
import SwiftUI
import Utils

enum Tab: Hashable, CaseIterable {
    case home
    case ranking
    case research
    case myInfo
}

/// 모달로 띄운 Route. 같은 Route를 다시 띄워도 새 표시로 인식되게 id를 따로 둔다.
struct PresentedRoute: Identifiable {
    let id = UUID()
    let route: AnyHashable
}

@MainActor
final class AppRouter: ObservableObject, Navigator {
    /// 로그인 여부 (루트 화면 게이팅)
    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var selectedTab: Tab = .home
    @Published private(set) var tabPaths: [Tab: NavigationPath] = [:]
    /// 로그인 전 화면(로그인·가입·비밀번호 찾기·취향 선택)의 스택 (TB6)
    @Published var authPath = NavigationPath()
    /// 새 Feature 화면을 모달로 띄울 때. AppEntryView가 sheet로 표시한다.
    @Published var presentedRoute: PresentedRoute?

    init(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    func path(for tab: Tab) -> NavigationPath {
        return tabPaths[tab] ?? NavigationPath()
    }

    func pathBinding(for tab: Tab) -> Binding<NavigationPath> {
        return Binding(
            get: { return self.path(for: tab) },
            set: { self.tabPaths[tab] = $0 }
        )
    }

    /// 탭바 선택. 지금 탭을 다시 누르면 그 탭의 루트로 돌아간다 (TB3)
    var tabSelection: Binding<Tab> {
        return Binding(
            get: { return self.selectedTab },
            set: { self.tapTab($0) }
        )
    }

    func tapTab(_ tab: Tab) {
        if tab == selectedTab {
            tabPaths[tab] = NavigationPath()
        } else {
            selectedTab = tab
        }
    }

    /// 다른 화면이 탭을 바꿀 때 (홈 화살표, TB4). 그 탭의 스택은 그대로 둔다
    func select(_ tab: Tab) {
        selectedTab = tab
    }

    /// 지금 탭의 스택을 이 경로로 바꾼다 (딥링크, TB7). 로그인 직후에도 탭 스택에 넣는다
    func replaceSelectedTabPath(with path: NavigationPath) {
        tabPaths[selectedTab] = path
    }

    /// 로그인 성공. 모든 스택을 비우고 홈 탭으로 (TB6)
    func completeLogin() {
        DLog("🔐 [Login] completeLogin - 모든 스택 초기화, 홈 탭")
        resetStacks()
        isLoggedIn = true
    }

    /// 로그아웃·탈퇴. 모든 스택을 비우고 로그인 화면으로 (TB6)
    func completeLogout() {
        DLog("🔐 [Login] completeLogout - 모든 스택 초기화, 로그인 화면")
        resetStacks()
        isLoggedIn = false
        AnalyticsManager.clearUser()
    }

    private func resetStacks() {
        tabPaths = [:]
        authPath = NavigationPath()
        selectedTab = .home
        presentedRoute = nil
    }

    // MARK: - Navigator (TB1·TB9)

    /// 로그인 전이면 로그인 스택, 아니면 지금 탭의 스택
    private var currentPath: NavigationPath {
        get { return isLoggedIn ? path(for: selectedTab) : authPath }
        set {
            if isLoggedIn {
                tabPaths[selectedTab] = newValue
            } else {
                authPath = newValue
            }
        }
    }

    func push(_ route: some Hashable & Sendable) {
        currentPath.append(route)
    }

    func pop() {
        guard !currentPath.isEmpty else {
            return
        }
        currentPath.removeLast()
    }

    func popToRoot() {
        currentPath = NavigationPath()
    }

    func present(_ route: some Hashable & Sendable) {
        presentedRoute = PresentedRoute(route: AnyHashable(route))
    }

    func dismiss() {
        presentedRoute = nil
    }
}
