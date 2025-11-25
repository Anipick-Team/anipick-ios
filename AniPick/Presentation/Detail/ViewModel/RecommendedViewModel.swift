//
//  RecommendedViewModel.swift
//  AniPick
//
//  Created by cho on 11/26/25.
//

import SwiftUI
import Alamofire

final class RecommendedViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int
    @Published var animeTitle: String
    
    @Published var recommendedAnimeList: [Anime] = []
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    var lastId: Int = 0
    
    init(
        navigationManager: NavigationManager,
        animeId: Int,
        animeTitle: String
    ) {
        self.navigationManager = navigationManager
        self.animeId = animeId
        self.animeTitle = animeTitle
    }
    
    func fetchRecommendationAnimeInfo() {
        session.request(
            AnimeAPI.recommendationAnime(
                animeId: self.animeId,
                lastId: self.lastId,
                size: 20
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecommendationResponse.self) { response in
            switch response.result {
            case let .success(value):
                DLog("anime recommendation response - \(response)")
                if let animeList = value.result,
                   let seriesInfo = animeList.animes {
                    self.recommendedAnimeList = seriesInfo
                    var lastId = animeList.cursor?.lastId
                    self.animeTitle = animeList.referenceAnimeTitle ?? "-"
                }
                
            case let .failure(error):
                
                DLog("anime recommendation Error: \(error)")
            }
        }
    }
}
