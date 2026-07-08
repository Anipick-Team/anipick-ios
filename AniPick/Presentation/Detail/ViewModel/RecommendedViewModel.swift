//
//  RecommendedViewModel.swift
//  AniPick
//
//  Created by cho on 11/26/25.
//

import SwiftUI
import Alamofire

@MainActor
final class RecommendedViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int
    @Published var animeTitle: String
    
    @Published var recommendedAnimeList: [Anime] = []
    
    private let session = NetworkSession.authenticated
    
    private var lastId: Int? = nil
    
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
                size: 10
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case let .success(value):
                DLog("anime recommendation response - \(response)")
                if let animeList = value.result,
                   let seriesInfo = animeList.animes {
                    let existingIds = Set(self.recommendedAnimeList.map { $0.animeId })
                    let newAnimes = seriesInfo.filter { !existingIds.contains($0.animeId) }
                    self.recommendedAnimeList += newAnimes
                    self.lastId = animeList.cursor?.lastId
                    self.animeTitle = animeList.referenceAnimeTitle ?? "-"
                }
                
            case let .failure(error):
                
                DLog("anime recommendation Error: \(error)")
            }
        }
    }
    
    func moveToAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
