//
//  AppState.swift
//  AniPick
//
//  Created by cho on 10/7/25.
//

import Combine
import SwiftUI
import Utils

@MainActor
final class AppState: ObservableObject {
    private let router: AppRouter
    private var cancellables = Set<AnyCancellable>()

    @Published var pendingExploreFilter: ExploreFilter?
    @Published var deepLink: DeepLink? {
        didSet {
            guard let deepLink else { return }
            handle(deepLink)
        }
    }
    /// 로그인 전에 들어온 딥링크. 로그인(신규 가입은 취향 선택 완료) 후 이동한다.
    private(set) var pendingDeepLink: DeepLink?

    init(router: AppRouter) {
        self.router = router

        router.$isLoggedIn
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.consumePendingDeepLink()
            }
            .store(in: &cancellables)
    }

    func handle(_ link: DeepLink) {
        switch link {
        case .anime, .communityPost:
            guard router.isLoggedIn else {
                DLog("로그인 전 딥링크 보관: \(link)")
                pendingDeepLink = link
                return
            }
            navigate(to: link)
        case .producer(let id):
            DLog("Producer Detail 이동 id: \(id)")
        case .unknown:
            // 카카오 로그인 콜백 등 앱 외부 URL도 여기로 온다. 보관 중인 딥링크를 덮어쓰지 않는다.
            DLog("알 수 없는 링크")
        }
    }

    private func consumePendingDeepLink() {
        guard let link = pendingDeepLink else { return }
        pendingDeepLink = nil
        DLog("보관된 딥링크 처리: \(link)")
        // $isLoggedIn은 값이 바뀌기 직전에 방출되므로 isLoggedIn을 다시 확인하지 않고 바로 이동한다.
        navigate(to: link)
    }

    /// 지금 탭의 스택을 딥링크 화면 하나로 한 번에 바꾼다 (TB7). 레거시는 popToRoot(Task) 뒤 0.3초를 기다려 push했다 (Phase 4-1에서 제거)
    private func navigate(to link: DeepLink) {
        guard let target = DeepLinkTarget.target(for: link) else {
            return
        }
        DLog("딥링크 이동: \(target)")
        router.replaceSelectedTabPath(with: target.path)
    }

    func pushExplore(year: String?, season: String?) {
        DLog("explore push push - \(year) - \(season)")
        pendingExploreFilter = .init(year: year, season: season)
    }

    func consumeExploreFilter() -> ExploreFilter? {
        defer { pendingExploreFilter = nil }
        return pendingExploreFilter
    }
    

}

struct ExploreFilter: Equatable {
    var year: String?
    var season: String?
}
