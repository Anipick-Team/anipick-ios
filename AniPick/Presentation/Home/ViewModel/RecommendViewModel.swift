//
//  RecommendViewModel.swift
//  AniPick
//
//  Created by cho on 1/20/26.
//

import Foundation
import Alamofire

final class RecommendViewModel: ObservableObject {
    @Published var recommedationAnimes: [Anime] = []
    @Published var recommedationTitle: String = ""
    
    private let navigationManager: NavigationManager
    private let animeId: Int
    var lastId: Int? = nil
    
    let session = Session(interceptor: TokenInterceptor.shared)
    init(navigationManager: NavigationManager, animeId: Int) {
        self.navigationManager = navigationManager
        self.animeId = animeId
    }
    
    func fetchRecommendationAnime() {
        session.request(RecommendationAPI.recommedation(lastId: lastId, lastValue: nil))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommedation success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommedationAnimes = recommend
                        self.lastId = animeList.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("fetch home recommedation error \(error)")
                }
            }
    }
    
    func getNextPage(lastAnimeId: Int) {
        if lastAnimeId == self.recommedationAnimes.last?.animeId {
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
