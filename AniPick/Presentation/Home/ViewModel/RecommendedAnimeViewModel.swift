//
//  RecommendedAnimeViewModel.swift
//  AniPick
//
//  Created by cho on 7/26/25.
//

import SwiftUI
import Alamofire

final class RecommendedAnimeViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int?
    
    @Published var recommedationAnimes: [Anime] = []
    @Published var recommedationTitle: String = ""
    let session = Session(interceptor: TokenInterceptor.shared)
    init(navigationManager: NavigationManager, animeId: Int? = nil) {
        self.navigationManager = navigationManager
        self.animeId = animeId
    }
}


extension RecommendedAnimeViewModel {
    func fetchRecommedationAnime() {
        if let animeId = self.animeId {
            session.request(RecommendationAPI.recommedationWithAnimeId(animeId: animeId))
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { response in
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommedation detail with anime success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommedationAnimes = recommend
                            self.recommedationTitle = animeList.referenceAnimeTitle ?? "--"
                        }
                    case .failure(let error):
                        DLog("fetch recommedation detail with anim error \(error)")
                    }
                }
        } else {
            session.request(RecommendationAPI.recommedation)
                .cURLDescription { description in
                    DLog("\(description)")
                }
                .responseDecodable(of: RecommendationResponse.self) { response in
                    switch response.result {
                    case .success(let value):
                        DLog("fetch recommedation detail success \(value)")
                        if let animeList = value.result,
                           let recommend = animeList.animes {
                            self.recommedationAnimes = recommend
                            self.recommedationTitle = animeList.referenceAnimeTitle ?? "--"
                        }
                    case .failure(let error):
                        DLog("fetch recommedation detail error \(error)")
                    }
                }
        }
    }
    
    func tappedAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }

}
