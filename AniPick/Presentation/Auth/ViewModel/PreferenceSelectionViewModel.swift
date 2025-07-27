//
//  PreferenceSelectionViewModel.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

import SwiftUI
import Alamofire

final class PreferenceSelectionViewModel: ObservableObject {
    
    @Published var animeList: [AnimePreference] = []
    @Published var ratedAnimeCount: Int = 0
    
    @Published var selectedGenre: String = ""
    @Published var selectedYear: String = ""
    @Published var selectedQuarter: String = ""
    @Published var searchBarString: String = ""
    
    @Published var isPresentModelView: Bool = false
        
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
}

extension PreferenceSelectionViewModel {
    func fetchMataData() {
        AF.request(MetaDataAPI.metaData)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: MetaDataResponse.self) { response in
                switch response.result {
                case .success(let value):
                    // TODO: 성공했으면 userdefatuls 업데이트하는 로직 필요
                    DLog("meta data fetch 성공 - \(value)")
                    let seasonYear = value.result.seasonYear
                    let animeType = value.result.type
                    let genres = value.result.genres
                    let season = value.result.season
                    
                    UserDefaultsManager.shared.setMetaDataForSeasonYear(seasonYear)
                    UserDefaultsManager.shared.setMetaDataForType(animeType)
                    UserDefaultsManager.shared.setMetaDataForGenres(genres)
                    UserDefaultsManager.shared.setMetaDataForSeason(season)
                    
                case .failure(let error):
                    // TODO: 실패했을 떄, 그냥 userdefautls 그대로 사용.
                    DLog("meta data fetch 실패 - \(error)")
                }
            }
    }
    
    func fetchRecommendAnime() {
        let genreList = UserDefaultsManager.shared.getMetaDataForGenres()
        guard let id = genreList.first(where: { $0.name == self.selectedGenre })?.id else {
            return
        }
        
        AF.request(
            AnimeAPI.preference(
                query: self.searchBarString,
                year: Int(self.selectedYear),
                season: Int(self.selectedQuarter),
                genre: id,
                lastId: nil
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: AnimePreferenceResponse.self) { response in
                switch response.result {
                case .success(let value):
                    if let anime = value.result,
                       let animeList = anime.animes {
                        self.animeList = animeList
                    }
                    DLog("취향선택 Ani - \(value)")
                case .failure(let error):
                    DLog("Auth 취향 선택 뷰 에러 - \(error)")
                }
            }
    }
    
    func tappedModalSaveButton() {
        
    }
    
    func tappedModelView() {
        self.isPresentModelView.toggle()
    }
}
