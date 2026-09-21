//
//  AppState.swift
//  AniPick
//
//  Created by cho on 10/7/25.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private let navigationManager: NavigationManager
    
    @Published var pendingExploreFilter: ExploreFilter?
    @Published var deepLink: DeepLink? {
        didSet {
            guard let deepLink else { return }
            handle(deepLink)
        }
    }
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    func handle(_ link: DeepLink) {
        switch link {
        case .anime(let id):
            DLog("Anime Detail 이동 id: \(id)")
            navigationManager.popToRoot()
            // popToRoot Task 처리 후 push 실행되도록 딜레이
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.navigationManager.push(route: .animeDetail(animeId: id))
            }
        case .producer(let id):
            DLog("Producer Detail 이동 id: \(id)")
        case .unknown:
            DLog("알 수 없는 링크")
        }
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
