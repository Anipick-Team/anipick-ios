//
//  RecommendViewModel.swift
//  AniPick
//
//  Created by cho on 1/20/26.
//

import Foundation
import Alamofire

@MainActor
final class RecommendViewModel: ObservableObject {
    @Published var recommendationAnimes: [Anime] = []
    @Published var recommendationTitle: String = ""
    
    private let navigationManager: NavigationManager
    private let animeId: Int
    let animeTitle: String?
    private var lastId: Int? = nil
    
    private let session = NetworkSession.authenticated
    init(navigationManager: NavigationManager, animeId: Int, animeTitle: String?) {
        self.navigationManager = navigationManager
        self.animeId = animeId
        self.animeTitle = animeTitle
        
    }
    
    func fetchRecommendationAnime() {
        session.request(RecommendationAPI.recommendation(lastId: lastId, lastValue: nil))
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
                        self.lastId = animeList.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("fetch home recommendation error \(error)")
                }
            }
    }
    
    func getNextPage(lastAnimeId: Int) {
        if lastAnimeId == self.recommendationAnimes.last?.animeId {
            self.fetchRecommendationAnime()
        }
    }
    
    func tappedAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}

extension RecommendViewModel {
    func fetchRecommendAnimation() {
        
    }
}
