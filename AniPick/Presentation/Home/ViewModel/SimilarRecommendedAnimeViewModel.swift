//
//  SimilarRecommendedAnimeViewModel.swift
//  AniPick
//
//  Created by cho on 7/26/25.
//

import SwiftUI
import Alamofire

final class SimilarRecommendedAnimeViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int?
    
    @Published var recommedationAnimes: [Anime] = []
    @Published var recommedationTitle: String = ""
    
    
    var lastId: Int? = nil
    var lastValue: String? = nil
    
    let session = Session(interceptor: TokenInterceptor.shared)
    init(navigationManager: NavigationManager, animeId: Int? = nil) {
        self.navigationManager = navigationManager
        self.animeId = animeId
    }
}


extension SimilarRecommendedAnimeViewModel {
    func fetchRecommedationAnime() {
        if let animeId = self.animeId {
            session.request(
                RecommendationAPI.recommedationWithAnimeId(
                    animeId: animeId,
                    lastId: self.lastId,
                    lastValue: self.lastValue
                )
            )
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { response in
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommedation detail with anime success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommedationAnimes.append(contentsOf: recommend)
                            self.recommedationTitle = animeList.referenceAnimeTitle ?? "--"
                            self.lastId = value.result?.cursor?.lastId
                            self.lastValue = value.result?.cursor?.lastValue
                        }
                    case .failure(let error):
                        DLog("fetch recommedation detail with anim error \(error)")
                    }
                }
        } else {
            session.request(
                RecommendationAPI.recommedation(
                    lastId: self.lastId,
                    lastValue: self.lastValue
                )
            )
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { response in
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommedation detail success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommedationAnimes.append(contentsOf: recommend)
                            self.recommedationTitle = animeList.referenceAnimeTitle ?? "--"
                            self.lastId = value.result?.cursor?.lastId
                        }
                    case .failure(let error):
                        DLog("fetch recommedation detail error \(error)")
                    }
                }
        }
    }
    
    func getNextPage(lastAnimeId: Int) {
        if lastAnimeId == self.recommedationAnimes.last?.animeId {
            self.fetchRecommedationAnime()
        }
    }
    
    func tappedAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }

}
