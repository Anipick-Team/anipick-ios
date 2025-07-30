//
//  ExploreViewModel.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI
import Alamofire

final class ExploreViewModel: ObservableObject {
    @Published var exploreItems: [Anime] = []
    @Published var selectedYear: String = ""
    @Published var selectedSeason: String = ""
    @Published var selectedGenres: Int = -1 // 메타데이터에서 id값으로 판단
    @Published var selectedType: String = ""
    @Published var selectedItems: [String] = []
    @Published var selectdCountList: [ExploreFilterTab] = []
    @Published var selectedAllClear: Bool = false
    
    @Published var countForYear: Int = 0
    @Published var countForGenre: Int = 0
    @Published var countFOrType: Int = 0
    var lastId: Int? = -1
    
    @Published var exploreRequestItem : ExploreReqeustItem? = nil
    @Published var selectedCategory: ExploreSortCategory = .popularity
    let session = Session(interceptor: TokenInterceptor.shared)
    
    private let usecase: ExploreUsecase
    private let navigationManager: NavigationManager
    
    init(usecase: ExploreUsecase, navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
}

extension ExploreViewModel {
    func getExploreItems(category: ExploreSortCategory) {
        session.request(ExploreAPI.exploreAnime(sort: category, item: self.exploreRequestItem))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ExploreResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("explore item init \(value)")
                    if let anime = value.result,
                       let animeList = anime.animes {
                        self.exploreItems = animeList
                        self.lastId = anime.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("failure \(error)")
                }
            }
    }
    
    // 무한 스크롤 시 불러오는 값
    func fetchMoreExploreItem(category: ExploreSortCategory) {
        session.request(ExploreAPI.exploreAnime(sort: category, item: self.exploreRequestItem))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ExploreResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("explore item loadmore \(value)")
                    if let anime = value.result,
                       let animeList = anime.animes {
                        
                        // ✅ 중복 animeId 제거
                        let existingIds = Set(self.exploreItems.map { $0.animeId })
                        let newItems = animeList.filter { !existingIds.contains($0.animeId) }
                        
                        self.exploreItems += newItems
                        self.lastId = anime.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("failure \(error)")
                }
            }
    }
    
    func fetchFiletedExploreData() {
        self.exploreRequestItem = ExploreReqeustItem(
            year: selectedYear.isEmpty ? nil : Int(selectedYear),
            season: selectedSeason.isEmpty ? nil : Int(selectedSeason),
            genres: selectedGenres == -1 ? nil : selectedGenres,
            type: selectedType.isEmpty ? nil : selectedType,
            lastId: lastId,
            size: nil,
            genreOp: nil, 
            lastValue: nil
        )
        
        DLog("확인확인 - \(self.selectedYear) \(self.selectedSeason)")
        self.fetchMoreExploreItem(category: self.selectedCategory)
        self.setSelectedItem()
        
    }
    
    func fetchInitFilteredExploreData() {
        self.exploreRequestItem = ExploreReqeustItem(
            year: selectedYear.isEmpty ? nil : Int(selectedYear),
            season: selectedSeason.isEmpty ? nil : Int(selectedSeason),
            genres: selectedGenres == -1 ? nil : selectedGenres,
            type: selectedType.isEmpty ? nil : selectedType,
            lastId: lastId,
            size: nil,
            genreOp: nil,
            lastValue: nil
        )
        
        DLog("확인확인 - \(self.selectedYear) \(self.selectedSeason)")
        self.getExploreItems(category: self.selectedCategory)
        self.setSelectedItem()
        
    }
    
    func setSelectedItem() {
        if self.selectedGenres > 0 {
            let genres = UserDefaultsManager.shared.getMetaDataForGenres()
            guard let name = genres.first(where: { $0.id == self.selectedGenres })?.name else {
                return
            }
            self.selectedItems.insert(name, at: 0)
            self.selectedGenres = -1
            self.countForGenre += 1
            self.selectdCountList.insert(.genre, at: 0)
        } else if self.selectedType.isEmpty == false {
            self.selectedItems.insert(self.selectedType, at: 0)
            self.selectedType = ""
            self.countFOrType += 1
            self.selectdCountList.insert(.type, at: 0)
        } else if self.selectedYear.isEmpty == false {
            if self.selectedSeason.isEmpty == false {
                self.selectedItems.insert(self.selectedSeason, at: 0)
                self.selectdCountList.insert(.yearQuarter, at: 0)
                self.selectedSeason = ""
            }
            self.selectedItems.insert(String(self.selectedYear), at: 0)
            self.selectedYear = ""
            self.countForYear += 1
            self.selectdCountList.insert(.yearQuarter, at: 0)
            // TODO: 연도와 분기를 함께 선택했을 때, 분기만 지웠을 떄 어떻게 되는지 로직 설정 추가 필요
        }
    }
    
    func removeTagView(index: Int) {
        selectedItems.remove(at: index)
        selectdCountList.remove(at: index)
        if selectedItems.isEmpty {
            self.countForYear = 0
            self.countForGenre = 0
            self.countFOrType = 0
            self.exploreRequestItem = nil
            self.lastId = nil
        }
        Task {
            await self.getExploreItems(category: self.selectedCategory)
        }
    }
    
    
    func tappedAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func allClearSelectedCategory() {
        self.selectedItems.removeAll()
        self.countForYear = 0
        self.countForGenre = 0
        self.countFOrType = 0
        self.exploreRequestItem = nil
        self.lastId = nil
    }
    
}
