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
    @Published var lastVisibleIndex: Int = 10
    @Published var selectedGenreId: Int? = nil
    @Published var selectedGenre: String = ""
    @Published var selectedYear: String = ""
    @Published var selectedQuarter: String = ""
    @Published var searchBarString: String = ""
    
    @Published var lastId: Int? = nil
    
    @Published var storedRatedAnimeList: [AuthAnimeRatingRequest] = []
    @Published var selectedAnimeList: Set<Int> = []
    @Published var isPresentModelView: Bool = false
        
    let session = Session(interceptor: TokenInterceptor.shared)
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
}

extension PreferenceSelectionViewModel {
    func fetchMataData() {
        session.request(MetaDataAPI.metaData)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: MetaDataResponse.self) { response in
                switch response.result {
                case .success(let value):
                    // TODO: 성공했으면 userdefatuls 업데이트하는 로직 필요
                    DLog("meta data fetch 성공 - \(value)")
                    let seasonYear = value.result?.seasonYear ?? []
                    let animeType = value.result?.type ?? []
                    let genres = value.result?.genres ?? []
                    let season = value.result?.season ?? []
                    
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
    
    func selectedGenre(name: String) {
        let genreList = UserDefaultsManager.shared.getMetaDataForGenres()
        if let actionId = genreList.first(where: { $0.name == name })?.id {
            DLog("\(name) 장르의 id 값")
            self.selectedGenreId = actionId
        }
    }
    
    func fetchRecommendAnime() {
        let genreList = UserDefaultsManager.shared.getMetaDataForGenres()
        session.request(
            AnimeAPI.preference(
                query: self.searchBarString.isEmpty ? nil : self.searchBarString,
                year: Int(self.selectedYear),
                season: Int(self.selectedQuarter),
                genre: self.selectedGenreId,
                lastId: self.lastId
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
                        self.animeList.append(contentsOf: animeList)
                        self.lastId = anime.cursor?.lastId
                    }
                    DLog("취향선택 Ani - \(value)")
                case .failure(let error):
                    DLog("Auth 취향 선택 뷰 에러 - \(error)")
                }
            }
    }
    
    func tappedEachRatedAnime(animeId: Int, rating: Double) {
            let newAnime = AuthAnimeRatingRequest(animeId: animeId, rating: rating)

            if let index = storedRatedAnimeList.firstIndex(where: { $0.animeId == animeId }) {
                // 이미 존재 → 업데이트
                DLog("index - \(index) newAnime - \(newAnime)")
                storedRatedAnimeList[index] = newAnime
            } else {
                // 없으면 추가
                DLog("newAnime - \(newAnime)")
                storedRatedAnimeList.append(newAnime)
            }
        }
    
    func isShowRatedAnime(animeId: Int) {
        if selectedAnimeList.contains(animeId) {
            selectedAnimeList.remove(animeId) // 이미 있으면 해제
          } else {
              selectedAnimeList.insert(animeId) // 없으면 추가
          }
    }
    
    func isRatedAnime(animeId: Int) -> Bool {
        return selectedAnimeList.contains(animeId)
    }
    
    func isRatedDoneAnime(animeId: Int) -> Bool {
        return storedRatedAnimeList.contains { $0.animeId == animeId }
    }
    
    func removeRatedAnime(animeId: Int) {
        self.storedRatedAnimeList.removeAll { $0.animeId == animeId }
    }
//    func isRatedAnime(animeId: Int) -> Bool {
//        return storedRatedAnimeList.contains { $0.animeId == animeId }
//    }
    // TODO: 완료를 눌렀을 떄, API 통신해서 값 보내기
    func tappedDoneRatedAnime() {
        AF.request(AnimeAPI.storedPreference(request: self.storedRatedAnimeList))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("회원가입 시, 취향선택 탭탭 - \(value)")
                case .failure(let error):
                    DLog("회원가입 시, 취향선택 탭탭 Error - \(error)")
                }
            }
    }
    func tappedAllClearButton() {
        self.searchBarString = ""
    }
    
    func moveToMainView() {
        self.navigationManager.push(route: .content(activeTab: .home))
    }
    
    func tappedModelView() {
        self.isPresentModelView.toggle()
        self.animeList.removeAll()
        self.fetchRecommendAnime()
    }
}
