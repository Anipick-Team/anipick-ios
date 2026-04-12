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
    @Published var commingSoonAnimes: [Anime] = []
    @Published var recommedationAnimes: [Anime] = []
    @Published var recommendationAnimesWithAnimeId: [Anime] = []
    @Published var recommendationSimilarAnimes: [Anime] = []
    @Published var recommedationTitle: String = ""
    @Published var recommedationFirstTitle: String = ""
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
//        session.request(HomeAPI.trending)
//            .cURLDescription { description in
//                DLog("\(description)")
//            }
//            .responseDecodable(of: TrendingAnimesResponse.self) { response in
//                switch response.result {
//                case .success(let value):
//                    DLog("fetch trending success \(value)")
//                    if let animeList = value.result {
//                        self.trendingAnimes = animeList
//                    }
//                case .failure(let error):
//                    DLog("fetch trending error \(error)")
//                }
//            }
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
                    DLog("fetch home recommedation success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommedationAnimes = recommend
                        self.referenceAnimeTitle = animeList.referenceAnimeTitle
                    }
                case .failure(let error):
                    DLog("fetch home recommedation error \(error)")
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
           // DLog("upcoming Animes - \(self.upcomingAnimes)")
        } catch {
            DLog("upcoming Animes - \(error.localizedDescription)")
        }
    }
    
    func getComingSoonSeason() async {
        do {
            let response = try await usecase.getComingSoonAnimes()
            self.commingSoonAnimes = response.result
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
                    DLog("fetch home recommedation with animeid success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationAnimesWithAnimeId = recommend
                        self.recommedationTitle = animeList.referenceAnimeTitle ?? "--"
                    }
                case .failure(let error):
                    DLog("fetch home recommedation with animeid error \(error)")
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
                    DLog("fetch home recommedation with animeid success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationSimilarAnimes = recommend
                    }
                    self.recommedationFirstTitle = value.result?.referenceAnimeTitle ?? "-"
                case .failure(let error):
                    DLog("fetch home recommedation with animeid error \(error)")
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
    
    func moveToCommingSoonView() {
        self.navigationManager.push(route: .commingSoonDetail)
    }
    
    func moveToRecentReviewView() {
        self.navigationManager.push(route: .recentReview)
    }
    
    func moveToRecommendationView(animeId: Int, animeTitle: String? = nil) {
        self.navigationManager.push(route: .recommend2(animeId: animeId, animeTitle: animeTitle))
 //       self.navigationManager.push(route: .recommendView(animeId: animeId))
    }
    
    func moveToSimilarRecommendationView() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        self.navigationManager.push(route: .recommendView(animeId: animeId))
    }
    
    func moveToRankingView() {
        self.navigationManager.push(route: .content(activeTab: .ranking))
    }
}
