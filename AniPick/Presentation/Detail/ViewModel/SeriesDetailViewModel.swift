//
//  SeriesDetailViewModel.swift
//  AniPick
//
//  Created by cho on 11/23/25.
//

import SwiftUI
import Alamofire

final class SeriesDetailViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let animeId: Int
    @Published var animeTitle: String
    @Published var animeList: [SeriesAnime] = []
    @Published var count: Int = 0
    let session = Session(interceptor: TokenInterceptor.shared)
    var lastId: Int? = nil
    
    init(
        navigationManager: NavigationManager,
        animeId: Int,
        animeTitle: String
    ) {
        self.navigationManager = navigationManager
        self.animeId = animeId
        self.animeTitle = animeTitle
    }
    
    func getSeriesDetailInfo() {
        self.lastId = nil
        session.request(AnimeAPI.seriesAnimeList(
            animeId: self.animeId,
            lastId: lastId,
            size: 20)
        )
        .cURLDescription { des in
            DLog("series Detail Info - \(des)")
        }
        .responseDecodable(of: SeriesAnimeResponse.self) { response in
            switch response.result {
            case .success(let response):
                DLog("series Detail success - \(response)")
                if let result = response.result {
                    self.animeList = result.animes ?? []
                    self.count = result.count
                    self.lastId = result.cursor?.lastId
                }
            case .failure(let error):
                DLog("Series Detail fail - \(error)")
            }
        }
    }
    
    func getLoadMoreSeriesDetailInfo() {
        session.request(AnimeAPI.seriesAnimeList(
            animeId: self.animeId,
            lastId: lastId,
            size: 20)
        )
        .cURLDescription { des in
            DLog("series Detail Info - \(des)")
        }
        .responseDecodable(of: SeriesAnimeResponse.self) { response in
            switch response.result {
            case .success(let response):
                DLog("series Detail success - \(response)")
                if let result = response.result {
                    self.animeList += result.animes ?? []
                    self.count = result.count
                    self.lastId = result.cursor?.lastId
                }
            case .failure(let error):
                DLog("Series Detail fail - \(error)")
            }
        }
    }
    
    func moveToAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
