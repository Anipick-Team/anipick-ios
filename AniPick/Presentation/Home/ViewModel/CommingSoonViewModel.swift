//
//  ComingSoonViewModel.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//

import SwiftUI
import Alamofire

@MainActor
final class ComingSoonViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    @Published var comingSoonAnimeList: [UpcomingAnime] = []
    @Published var selectedCategory: ComingSoonSortCategory = .latest
    
    // 최신순, 인긴순, 방영 예정 순 확인 필요
    @Published var isShowSortCategoryOptionView: Bool = false
    @Published var isIncludeAdult: Bool = false
    private let session = NetworkSession.authenticated
    private var lastId: Int?
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
}

extension ComingSoonViewModel {
    func fetchComingSoonInfo() {
        // 정렬 (latest/popularity /startDate )
        session.request(
            AnimeAPI.comingSoonInfo(
                sort: self.selectedCategory.rawValue,
                lastId: nil,
                includeAdult: self.isIncludeAdult,
                lastValue: nil
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: UpcomingAnimeListResponse.self) { [weak self] response in
                guard let self else { return }
            switch response.result {
            case .success(let value):
                DLog("fetch home - detail - comingSoon success \(value)")
                if let animeList = value.result,
                   let recommend = animeList.animes {
                    self.comingSoonAnimeList = recommend
                    self.lastId = value.result?.cursor?.lastId
                }
                
                
            case .failure(let error):
                DLog("fetch home - detail - comingSoo error \(error)")
            }
        }
        
    }
    
    func loadMoreComingSoonInfo() {
        guard let lastId = lastId else { return }

        session.request(
            AnimeAPI.comingSoonInfo(
                sort: self.selectedCategory.rawValue,
                lastId: lastId,
                includeAdult: self.isIncludeAdult,
                lastValue: nil
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: UpcomingAnimeListResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case .success(let value):
                DLog("✅ 추가 로드 성공")
                if let animeList = value.result,
                   let recommend = animeList.animes {
                    
                    // ✅ 중복 animeId 제거
                    let existingIds = Set(self.comingSoonAnimeList.map { $0.animeId })
                    let newItems = recommend.filter { !existingIds.contains($0.animeId) }
                    
                    self.comingSoonAnimeList += newItems
                    self.lastId = value.result?.cursor?.lastId
    
                }
            case .failure(let error):
                DLog("❌ 추가 로드 실패: \(error)")
            }
        }
    }
    
    func toggleIncludeAdult() {
        self.isIncludeAdult.toggle()
        self.comingSoonAnimeList.removeAll()
        self.fetchComingSoonInfo()
    }
    
    func tappedSortButton() {
        self.isShowSortCategoryOptionView.toggle()
        self.comingSoonAnimeList.removeAll()
        self.fetchComingSoonInfo()
    }
    
    func tappedAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
