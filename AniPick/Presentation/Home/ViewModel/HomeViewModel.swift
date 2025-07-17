//
//  HomeViewModel.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//

import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trendingAnimes: [TrendingAnimes] = []
    @Published var recentReviews: [Review] = []
    @Published var upcomingAnimes: AnimeSeasonResult?
    @Published var commingSoonAnimes: [Anime] = []
    
    private let usecase: HomeUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(usecase: HomeUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
}

extension HomeViewModel {
    func getTrendingAnimes() async {
        do {
            let response = try await usecase.getTrendingAnimes()
            guard let anime = response.result else {
                return
            }
            self.trendingAnimes = anime
            DLog("trending Animes - \(self.trendingAnimes)")
        } catch {
            DLog("trending Animes fail - \(error.localizedDescription)")
        }
    }
    
    func getRecentsReviews() async {
        do {
            let response = try await usecase.getRecentReviews()
            self.recentReviews = response.result
            DLog("recent Reviews - \(self.recentReviews)")
        } catch {
            DLog("recentReview - \(error.localizedDescription)")
        }
    }
    
    func getUpComingSeason() async {
        do {
            let response = try await usecase.getUpcomingAnimes()
            self.upcomingAnimes = response.result
            DLog("upcoming Animes - \(self.upcomingAnimes)")
        } catch {
            DLog("upcoming Animes - \(error.localizedDescription)")
        }
    }
    
    func getComingSoonSeason() async {
        do {
            let response = try await usecase.getComingSoonAnimes()
            self.commingSoonAnimes = response.result
            DLog("coming Soon - \(self.upcomingAnimes)")
        } catch {
            DLog("coming Soon - \(error.localizedDescription)")
        }
    }
    
    func moveToSearchView() {
        self.navigationManager.push(route: AppRoute.homeSearch)
    }
    
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
