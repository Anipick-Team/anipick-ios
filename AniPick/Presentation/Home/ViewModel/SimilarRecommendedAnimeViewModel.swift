//
//  SimilarRecommendedAnimeViewModel.swift
//  AniPick
//
//  Created by cho on 7/26/25.
//

import SwiftUI
import Alamofire

@MainActor
final class SimilarRecommendedAnimeViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int?
    
    @Published var recommendationAnimes: [Anime] = []
    @Published var recommendationTitle: String = ""
    
    
    private var lastId: Int? = nil
    private var lastValue: String? = nil
    
    private let session = NetworkSession.authenticated
    init(navigationManager: NavigationManager, animeId: Int? = nil) {
        self.navigationManager = navigationManager
        self.animeId = animeId
    }
}


extension SimilarRecommendedAnimeViewModel {
    func fetchRecommendationAnime() {
        if let animeId = self.animeId {
            session.request(
                RecommendationAPI.recommendationWithAnimeId(
                    animeId: animeId,
                    lastId: self.lastId,
                    lastValue: self.lastValue
                )
            )
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                    guard let self else { return }
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommendation detail with anime success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommendationAnimes.append(contentsOf: recommend)
                            self.recommendationTitle = animeList.referenceAnimeTitle ?? "--"
                            self.lastId = value.result?.cursor?.lastId
                            self.lastValue = value.result?.cursor?.lastValue
                        }
                    case .failure(let error):
                        DLog("fetch recommendation detail with anim error \(error)")
                    }
                }
        } else {
            session.request(
                RecommendationAPI.recommendation(
                    lastId: self.lastId,
                    lastValue: self.lastValue
                )
            )
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                    guard let self else { return }
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommendation detail success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommendationAnimes.append(contentsOf: recommend)
                            self.recommendationTitle = animeList.referenceAnimeTitle ?? "--"
                            self.lastId = value.result?.cursor?.lastId
                        }
                    case .failure(let error):
                        DLog("fetch recommendation detail error \(error)")
                    }
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
