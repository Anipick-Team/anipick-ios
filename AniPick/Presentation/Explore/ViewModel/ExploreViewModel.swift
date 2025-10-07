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
    @Published var selectedGenres: Int = -1
    @Published var selectedType: String = ""
    @Published var selectedTagItems: [String] = []
    @Published var selectdCountList: [ExploreFilterTab] = []
    @Published var selectedAllClear: Bool = false
    @Published var selectedGenreList: [Int] = []
    
    @Published var selectedGenreNameList: [String] = []
    
    @Published var selectedTagList: [ExploreSelectedTag] = []
        
    @Published var isToggleAllGenreCondition: Bool = false
    var lastId: Int? = nil

    
    @Published var exploreRequestItem : ExploreReqeustItem? = nil
    @Published var selectedCategory: ExploreSortCategory = .popularity
    
    @Published var isShowSortOptionView: Bool = false
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    private let usecase: ExploreUsecase
    private let navigationManager: NavigationManager
    
    init(usecase: ExploreUsecase, navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
}

struct ExploreSelectedTag: Hashable, Identifiable {
    let id = UUID()
    let category: ExploreFilterTab
    let value: String // 년도,분기, 장르, 타입 값
}

extension ExploreViewModel {
//    private func getExploreItems(category: ExploreSortCategory) {
//        session.request(
//            ExploreAPI.exploreAnime(
//                sort: category,
//                item: self.exploreRequestItem
//            )
//        )
//            .cURLDescription { description in
//                DLog("\(description)")
//            }
//            .responseDecodable(of: ExploreResponse.self) { response in
//                switch response.result {
//                case .success(let value):
//                    DLog("explore item init \(value)")
//                    if let anime = value.result,
//                       let animeList = anime.animes {
//                        self.exploreItems = animeList
//                        self.lastId = anime.cursor?.lastId
//                    }
//                case .failure(let error):
//                    DLog("failure \(error)")
//                }
//            }
//    }
    
    // 년도/분기, 장르, 타입 등에서 완료버튼을 눌렀을 때, 적용되어야할 것들
    // 1. 년도, 분기, 타입의 경우 바뀌었다면 바뀐 값으로 새로운 값 불러와야함
    // 2. 장르의 경우 추가되었을 수 있음. 그것도 추가된 값으로 불러와야함
    // 3. 추가된 경우, tag를 생성해야함.
    // 4. 초기화의 경우, 모든 tag과 선택된 값을 없애야함
    func tappedDoneFilteredCategory() {
        if !selectedYear.isEmpty {
            let item = ExploreSelectedTag(category: .yearQuarter, value: selectedYear)
            
            // 같은 category & value가 이미 있는지 검사
            if !selectedTagList.contains(where: { $0.category == item.category && $0.value == item.value }) {
                selectedTagList.insert(item, at: 0)
            }
        }

        if !selectedGenreNameList.isEmpty {
            for name in selectedGenreNameList {
                let tmp = ExploreSelectedTag(category: .genre, value: name)
                
                if !selectedTagList.contains(where: { $0.category == tmp.category && $0.value == tmp.value }) {
                    selectedTagList.insert(tmp, at: 0)
                }
            }
        }

        if !selectedType.isEmpty {
            let item = ExploreSelectedTag(category: .type, value: selectedType)
            
            if !selectedTagList.contains(where: { $0.category == item.category && $0.value == item.value }) {
                selectedTagList.insert(item, at: 0)
            }
        }

//        if selectedYear.isEmpty == false {
//            // TODO: year과 전체분기 따져야함 // 분기만 선택했을 때는,,,?
//            let item = ExploreSelectedTag(category: .yearQuarter, value: "\(selectedYear)")
//            self.selectedTagList.insert(item, at: 0)
//        }
//        
//        if selectedGenreNameList.isEmpty == false {
//            for item in self.selectedGenreNameList {
//                let tmp = ExploreSelectedTag(category: .genre, value: item)
//                self.selectedTagList.insert(tmp, at: 0)
//            }
//        }
//        
//        if selectedType.isEmpty == false {
//            let item = ExploreSelectedTag(category: .type, value: self.selectedType)
//            self.selectedTagList.insert(item, at: 0)
//        }
    }
    
//    func setSelectedItem() {
//        if self.selectedGenreList.isEmpty == false {
//            let genres = UserDefaultsManager.shared.getMetaDataForGenres()
//            for id in self.selectedGenreList {
//                if let name = genres.first(where: { $0.id == id })?.name {
//                    if !self.selectedTagItems.contains(name) {
//                        self.selectedTagItems.insert(name, at: 0)
//                        self.selectdCountList.insert(.genre, at: 0)
//                    }
//                }
//            }
//        } else if self.selectedType.isEmpty == false {
//            self.selectedTagItems.insert(self.selectedType, at: 0)
//            self.selectedType = ""
//            self.selectdCountList.insert(.type, at: 0)
//        } else if self.selectedYear.isEmpty == false {
//            if self.selectedSeason.isEmpty == false {
//                self.selectedTagItems.insert(self.selectedSeason, at: 0)
//                self.selectdCountList.insert(.yearQuarter, at: 0)
//                self.selectedSeason = ""
//            }
//            self.selectedTagItems.insert(String(self.selectedYear), at: 0)
//            self.selectedYear = ""
//            self.selectdCountList.insert(.yearQuarter, at: 0)
//            // TODO: 연도와 분기를 함께 선택했을 때, 분기만 지웠을 떄 어떻게 되는지 로직 설정 추가 필요
//        }
//    }
    
    // 인기순, 평점순 나누는 값
    func tappedSortButton() {
        self.lastId = nil
        self.isShowSortOptionView.toggle()
        self.exploreItems.removeAll()
     //   self.getExploreItems(category: self.selectedCategory)
        // 🐳
        self.fetchMoreExploreItem(category: self.selectedCategory)
    }
    
    // 첫 애니메이션 가져오는 값
    func fetchExploreItem(category: ExploreSortCategory) {
        self.exploreItems.removeAll()
        session.request(
            ExploreAPI.exploreAnime(
                sort: category,
                item: self.exploreRequestItem
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ExploreResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("explore item loadmore success - \(value.code) - \(value.result?.count)")
                    if let anime = value.result,
                       let animeList = anime.animes {
//                        let existingIds = Set(self.exploreItems.map { $0.animeId })
//                        let newItems = animeList.filter { !existingIds.contains($0.animeId) }
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
        session.request(
            ExploreAPI.exploreAnime(
                sort: category,
                item: self.exploreRequestItem
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ExploreResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("explore item loadmore \(value)")
                    if let anime = value.result,
                       let animeList = anime.animes {
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
    
    func removeItemGenreList(idx: Int) {
        if let index = selectedGenreList.firstIndex(of: idx) {
            DLog("selectedGenrList 확인 before - \(selectedGenreList)")
            selectedGenreList.remove(at: index)
            DLog("selectedGenrList 확인 after - \(selectedGenreList)")
        }
    }
    
    // TODO: 선택된 tag 중에 장르는 다 없애고 전체로 만들어야함
    func tappedAllCondition() {
//        let genreList = UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
//        for genre in genreList {
//            self.selectedTagItems.removeAll { $0 == genre }
//        }
//        self.selectedGenreList.removeAll()
        self.selectedTagList.removeAll { $0.category == .genre }
        self.selectedGenreList.removeAll()
    }
    
    // 애니메이션 가져오는 fetch 함수
    func fetchFiletedExploreData() {
        
        let yearString = selectedTagList.first(where: { $0.category == .yearQuarter })?.value
        let yearInt = yearString.flatMap { Int($0) }
    
        let seasonString = selectedTagList.first(where: { $0.category == .season })?.value
        let seasonInt = seasonString.flatMap { Int($0) }
        
        let typeString = selectedTagList.first(where: { $0.category == .type })?.value
        let type = typeString.flatMap { $0 }
    
        let allGenres = UserDefaultsManager.shared.getMetaDataForGenres()
        let genreStringList = selectedTagList
            .filter { $0.category == .genre }
            .map { $0.value }
        let selectedGenreIdList: [Int]? = genreStringList.isEmpty ? nil : allGenres.filter { genreStringList.contains($0.name)}
            .map { $0.id }
        
        self.exploreRequestItem = ExploreReqeustItem(
            year: yearInt,
            season: seasonInt, //selectedSeason.isEmpty ? nil : Int(selectedSeason),
            genres: selectedGenreIdList,//selectedGenreList.isEmpty ? nil : selectedGenreList,
            type: type,//selectedType.isEmpty ? nil : selectedType,
            lastId: lastId,
            size: nil,
            genreOp: nil, 
            lastValue: nil
        )
        
        DLog("확인확인 year season - \(self.selectedYear) \(self.selectedSeason)")
        self.fetchMoreExploreItem(category: self.selectedCategory)
    //    self.setSelectedItem()
    }
    
    // 처음 애니메이션 가져오는 fetch 함수
    func fetchInitFilteredExploreData() {
        let yearString = selectedTagList.first(where: { $0.category == .yearQuarter })?.value
        let yearInt = yearString.flatMap { Int($0) }
    
        let seasonString = selectedTagList.first(where: { $0.category == .season })?.value
        let seasonInt = seasonString.flatMap { Int($0) }
        
        let typeString = selectedTagList.first(where: { $0.category == .type })?.value
        let type = typeString.flatMap { $0 }
    
        let allGenres = UserDefaultsManager.shared.getMetaDataForGenres()
        let genreStringList = selectedTagList
            .filter { $0.category == .genre }
            .map { $0.value }
        let selectedGenreIdList: [Int]? = genreStringList.isEmpty ? nil : allGenres.filter { genreStringList.contains($0.name)}
            .map { $0.id }
        
        self.exploreRequestItem = ExploreReqeustItem(
            // year: selectedYear.isEmpty ? nil : Int(selectedYear),
            year: yearInt,
            season: seasonInt, //selectedSeason.isEmpty ? nil : Int(selectedSeason),
            genres: selectedGenreIdList,//selectedGenreList.isEmpty ? nil : selectedGenreList,
            type: typeString,//selectedType.isEmpty ? nil : selectedType,
            lastId: nil,
            size: nil,
            genreOp: nil,
            lastValue: nil
        )
        //   self.getExploreItems(category: self.selectedCategory)
        // 🐳
        self.fetchExploreItem(category: self.selectedCategory)
     //   self.setSelectedItem()
    }

    func removeTagView(item: ExploreSelectedTag) {
        self.selectedTagList.removeAll { $0.id == item.id }
    }
    
//    func removeTagView(index: Int) {
//        DLog("tagItem before - \(selectedTagItems) \(selectdCountList)")
//        selectedTagItems.remove(at: index)
//        let type = selectdCountList[index]
//        switch type {
//        case .yearQuarter:
//            <#code#>
//        case .genre:
//            self.selectedGenreList.remove(at: index)
//        case .type:
//            <#code#>
//        }
//        selectdCountList.remove(at: index)
//        
//        DLog("tagItem after - \(selectedTagItems) \(selectdCountList)")
//        if selectedTagItems.isEmpty {
//            self.exploreRequestItem = nil
//        }
//        self.lastId = nil
//        // 🐳
//        self.fetchMoreExploreItem(category: self.selectedCategory)
// //       Task {
////            await self.getExploreItems(category: self.selectedCategory)
////        }
//    }
//    
    // 초기화 버튼 탭 시, 실행
    func allClearSelectedCategory() {
        self.selectedType = ""
        self.selectedYear = ""
        self.selectedSeason = ""
        self.selectedGenreList.removeAll()
        self.selectedTagList.removeAll()
   //     self.selectedTagItems.removeAll()
     //   self.selectdCountList.removeAll()
        self.exploreRequestItem = nil
        self.lastId = nil
    }
    
    // 태그에 해당 filterTab이 있으면 색깔이 남아있도록 판단하는 함수
    // TODO: delete me
//    func checkFilterColored(selectedTab: ExploreFilterTab) -> Bool {
//        return selectdCountList.contains(selectedTab)
//    }
    
}


// MARK: - navigation
extension ExploreViewModel {
    func tappedAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
