//
//  CommingSoonViewModel.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//

import SwiftUI
import Alamofire

final class CommingSoonViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    @Published var commingSoonAnimeList: [UpcomingAnime] = []
    @Published var selectedCategory: CommingSoonSortCategory = .latest
    
    // 최신순, 인긴순, 방영 예정 순 확인 필요
    @Published var isShowSortCategoryOptionView: Bool = false
    @Published var isIncludeAdult: Bool = false
    
    var lastId: Int?
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
}

extension CommingSoonViewModel {
    func fetchCommingSoonInfo() {
        // 정렬 (latest/popularity /startDate )
        AF.request(
            AnimeAPI.commingSoonInfo(
                sort: self.selectedCategory.rawValue,
                lastId: nil,
                includeAdult: self.isIncludeAdult,
                lastValue: nil
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: UpcomingAnimeListResponse.self) { response in
            switch response.result {
            case .success(let value):
                DLog("fetch home - detail - commingSoon success \(value)")
                if let animeList = value.result,
                   let recommend = animeList.animes {
                    self.commingSoonAnimeList = recommend
                    self.lastId = value.result?.cursor?.lastId
                }
                
                
            case .failure(let error):
                DLog("fetch home - detail - commingSoo error \(error)")
            }
        }
        
    }
    
    func loadMoreCommingSoonInfo() {
        guard let lastId = lastId else { return }

        AF.request(
            AnimeAPI.commingSoonInfo(
                sort: self.selectedCategory.rawValue,
                lastId: lastId,
                includeAdult: self.isIncludeAdult,
                lastValue: nil
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: UpcomingAnimeListResponse.self) { response in
            switch response.result {
            case .success(let value):
                DLog("✅ 추가 로드 성공")
                if let animeList = value.result,
                   let recommend = animeList.animes {
                    
                    // ✅ 중복 animeId 제거
                    let existingIds = Set(self.commingSoonAnimeList.map { $0.animeId })
                    let newItems = recommend.filter { !existingIds.contains($0.animeId) }
                    
                    self.commingSoonAnimeList += newItems
                    self.lastId = value.result?.cursor?.lastId
    
                }
            case .failure(let error):
                DLog("❌ 추가 로드 실패: \(error)")
            }
        }
    }
    
    func toggleIncludeAdult() {
        self.isIncludeAdult.toggle()
        self.commingSoonAnimeList.removeAll()
        self.fetchCommingSoonInfo()
    }
    
    func tappedSortButton() {
        self.isShowSortCategoryOptionView.toggle()
        self.commingSoonAnimeList.removeAll()
        self.fetchCommingSoonInfo()
    }
    
    func tappedAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
