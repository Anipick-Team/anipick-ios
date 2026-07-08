//
//  HomeViewModel.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//

import SwiftUI
import Alamofire

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trendingAnimes: [TrendingAnimes] = []
    @Published var recentReviews: [Review] = []
    @Published var upcomingAnimes: [Anime] = []
    @Published var comingSoonAnimes: [Anime] = []
    @Published var recommendationAnimes: [Anime] = []
    @Published var recommendationAnimesWithAnimeId: [Anime] = []
    @Published var recommendationSimilarAnimes: [Anime] = []
    @Published var recommendationTitle: String = ""
    @Published var recommendationFirstTitle: String = ""
    @Published var seasonString: Int = 0
    @Published var seasonYearString: Int = 0
    @Published var referenceAnimeTitle: String? = nil
    
    private let session = NetworkSession.authenticated
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
            self.trendingAnimes = response.result ?? []
            DLog("trending Anime List success - \(self.trendingAnimes)")
        } catch {
            DLog("trending Anime List error - \(error.localizedDescription)")
        }
    }
    
    func fetchRecommendationAnime() {
        session.request(AnimeRecommendationAPI.recommendation)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationAnimes = recommend
                        self.referenceAnimeTitle = animeList.referenceAnimeTitle
                    }
                case .failure(let error):
                    DLog("fetch home recommendation error \(error)")
                }
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
            self.upcomingAnimes = response.result.animes
            self.seasonString = response.result.season
            self.seasonYearString = response.result.seasonYear
            DLog("방영 예정 잘 받아와짐")
        } catch {
            DLog("upcoming Animes - \(error.localizedDescription)")
        }
    }
    
    func getComingSoonSeason() async {
        do {
            let response = try await usecase.getComingSoonAnimes()
            self.comingSoonAnimes = response.result
            DLog("공개 예정 잘 받아와짐")
        } catch {
            DLog("coming Soon - \(error.localizedDescription)")
        }
    }
    
    func fetchRecommendationAnimeWithAnimeId() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        DLog("lastvisitedAnimeId - \(animeId)")
        session.request(HomeAPI.animeRecommendation(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation with animeid success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationAnimesWithAnimeId = recommend
                        self.recommendationTitle = animeList.referenceAnimeTitle ?? "--"
                    }
                case .failure(let error):
                    DLog("fetch home recommendation with animeid error \(error)")
                }
            }
    }
    
    
    // TODO: 최근 찾아보신 작품과 비슷한 작품 -> 가장 최근에 들어간 작품 userdefaults로 정리해두어야함
    func fetchSimilarAnime() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        session.request(HomeAPI.animeRecommendation(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation with animeid success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationSimilarAnimes = recommend
                    }
                    self.recommendationFirstTitle = value.result?.referenceAnimeTitle ?? "-"
                case .failure(let error):
                    DLog("fetch home recommendation with animeid error \(error)")
                }
            }
    }
    
    func moveToSearchView() {
        self.navigationManager.push(route: AppRoute.homeSearch)
    }
    
    func moveToExploreView(season: Int, year: Int) {
        AppDIContainer.appState.pushExplore(year: String(year), season: String(season))
        self.navigationManager.push(route: .content(activeTab: .research))
    }
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func moveToComingSoonView() {
        self.navigationManager.push(route: .comingSoonDetail)
    }
    
    func moveToRecentReviewView() {
        self.navigationManager.push(route: .recentReview)
    }
    
    func moveToRecommendationView(animeId: Int, animeTitle: String? = nil) {
        self.navigationManager.push(route: .recommend2(animeId: animeId, animeTitle: animeTitle))
    }
    
    func moveToSimilarRecommendationView() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        self.navigationManager.push(route: .recommendView(animeId: animeId))
    }
    
    func moveToRankingView() {
        self.navigationManager.push(route: .content(activeTab: .ranking))
    }
}
