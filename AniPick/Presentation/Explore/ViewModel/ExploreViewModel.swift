//
//  ExploreViewModel.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI
import Alamofire

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var exploreItems: [Anime] = []
    @Published var selectedYear: String = ""
    @Published var selectedSeason: String = ""
    @Published var selectedType: String = ""
    @Published var selectedAllClear: Bool = false
    @Published var selectedGenreList: [Int] = []

    @Published var selectedGenreNameList: [String] = []

    @Published var selectedTagList: [ExploreSelectedTag] = []

    @Published var isToggleAllGenreCondition: Bool = false
    @Published var lastId: Int? = nil
    @Published var exploreRequestItem : ExploreRequestItem? = nil
    @Published var selectedCategory: ExploreSortCategory = .popularity

    @Published var isShowSortOptionView: Bool = false

    @Published var metaGenreList: [String] = UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
    @Published var metaYearList: [String] = UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
    @Published var metaTypeList: [String] = UserDefaultsManager.shared.getMetaDataForType()

    private let session = NetworkSession.authenticated

    private let usecase: ExploreUsecase
    private let navigationManager: NavigationManager

    init(usecase: ExploreUsecase, navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }

    func fetchMetaDataIfNeeded() {
        guard metaGenreList.isEmpty || metaYearList.isEmpty || metaTypeList.isEmpty else { return }
        session.request(MetaDataAPI.metaData)
            .responseDecodable(of: MetaDataResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    let seasonYear = value.result?.seasonYear ?? []
                    let animeType = value.result?.type ?? []
                    let genres = value.result?.genres ?? []
                    let season = value.result?.season ?? []
                    UserDefaultsManager.shared.setMetaDataForSeasonYear(seasonYear)
                    UserDefaultsManager.shared.setMetaDataForType(animeType)
                    UserDefaultsManager.shared.setMetaDataForGenres(genres)
                    UserDefaultsManager.shared.setMetaDataForSeason(season)
                    self.metaGenreList = genres.map { $0.name }
                    self.metaYearList = seasonYear.map { String($0) }
                    self.metaTypeList = animeType
                case .failure(let error):
                    DLog("메타데이터 재시도 실패 - \(error)")
                }
            }
    }
}

struct ExploreSelectedTag: Hashable, Identifiable {
    let id = UUID()
    let category: ExploreFilterTab
    let value: String // 년도,분기, 장르, 타입 값
}

extension ExploreViewModel {

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
    }

    // 인기순, 평점순 나누는 값
    func tappedSortButton() {
        self.lastId = nil
        self.exploreItems = []
        self.isShowSortOptionView.toggle()
        self.fetchInitFilteredExploreData()
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
            .responseDecodable(of: ExploreResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("explore item loadmore success - \(value.code) - \(value.result?.count)")
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
        session.request(
            ExploreAPI.exploreAnime(
                sort: category,
                item: self.exploreRequestItem
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ExploreResponse.self) { [weak self] response in
                guard let self else { return }
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
        self.selectedTagList.removeAll { $0.category == .genre }
        self.selectedGenreList.removeAll()
    }
    
    // 애니메이션 가져오는 fetch 함수
    func fetchFilteredExploreData() {
        
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
        
        self.exploreRequestItem = ExploreRequestItem(
            year: yearInt,
            season: seasonInt,
            genres: selectedGenreIdList,
            type: type,
            lastId: self.lastId,
            size: nil,
            genreOp: self.isToggleAllGenreCondition ? "AND" : "OR",
            lastValue: nil
        )

        self.fetchMoreExploreItem(category: self.selectedCategory)
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
        
        self.exploreRequestItem = ExploreRequestItem(
            // year: selectedYear.isEmpty ? nil : Int(selectedYear),
            year: yearInt,
            season: seasonInt, //selectedSeason.isEmpty ? nil : Int(selectedSeason),
            genres: selectedGenreIdList,//selectedGenreList.isEmpty ? nil : selectedGenreList,
            type: typeString,//selectedType.isEmpty ? nil : selectedType,
            lastId: nil,
            size: nil,
            genreOp: self.isToggleAllGenreCondition ? "AND" : "OR",
            lastValue: nil
        )
        self.fetchExploreItem(category: self.selectedCategory)
    }

    func removeTagView(item: ExploreSelectedTag) {
        self.selectedTagList.removeAll { $0.id == item.id }
    }
    
    // 초기화 버튼 탭 시, 실행
    func allClearSelectedCategory() {
        self.selectedType = ""
        self.selectedYear = ""
        self.selectedSeason = ""
        self.selectedType = ""
        self.selectedGenreList.removeAll()
        self.selectedTagList.removeAll()
        self.exploreRequestItem = nil
        self.lastId = nil
    }
}


// MARK: - navigation
extension ExploreViewModel {
    func tappedAnime(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func moveToSearchView() {
        self.navigationManager.push(route: AppRoute.homeSearch)
    }
}
