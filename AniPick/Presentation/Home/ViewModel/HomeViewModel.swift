//
//  HomeViewModel.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//

import SwiftUI
import Alamofire

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trendingAnimes: [TrendingAnimes] = []
    @Published var recentReviews: [Review] = []
    @Published var upcomingAnimes: [Anime] = []
    @Published var comingSoonAnimes: [Anime] = []
    @Published var weekdayNewAnimes: [Anime] = []
    @Published private(set) var selectedWeekday: WeekdayNewAnimeDay = .today
    @Published var recommendationAnimes: [Anime] = []
    @Published var recommendationAnimesWithAnimeId: [Anime] = []
    @Published var recommendationSimilarAnimes: [Anime] = []
    @Published var recommendationTitle: String = ""
    @Published var recommendationFirstTitle: String = ""
    @Published var seasonString: Int = 0
    @Published var seasonYearString: Int = 0
    @Published var referenceAnimeTitle: String? = nil
    
    private let session = NetworkSession.authenticated
    private let usecase: HomeUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(usecase: HomeUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
}

extension HomeViewModel {
    
    func getTrendingAnimes() async {
        do {
            let response = try await usecase.getTrendingAnimes()
            self.trendingAnimes = response.result ?? []
            DLog("trending Anime List success - \(self.trendingAnimes)")
        } catch {
            DLog("trending Anime List error - \(error.localizedDescription)")
        }
    }
    
    func fetchRecommendationAnime() {
        session.request(AnimeRecommendationAPI.recommendation)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationAnimes = recommend
                        self.referenceAnimeTitle = animeList.referenceAnimeTitle
                    }
                case .failure(let error):
                    DLog("fetch home recommendation error \(error)")
                }
            }
    }
    
    
    
    func getRecentsReviews() async {
        do {
            let response = try await usecase.getRecentReviews()
            self.recentReviews = response.result
            DLog("recent Reviews - \(self.recentReviews)")
        } catch {
            DLog("recentReview - \(error.localizedDescription)")
        }
    }
    
    func getUpComingSeason() async {
        do {
            let response = try await usecase.getUpcomingAnimes()
            self.upcomingAnimes = response.result.animes
            self.seasonString = response.result.season
            self.seasonYearString = response.result.seasonYear
            DLog("방영 예정 잘 받아와짐")
        } catch {
            DLog("upcoming Animes - \(error.localizedDescription)")
        }
    }
    
    func getComingSoonSeason() async {
        do {
            let response = try await usecase.getComingSoonAnimes()
            self.comingSoonAnimes = response.result
            DLog("공개 예정 잘 받아와짐")
        } catch {
            DLog("coming Soon - \(error.localizedDescription)")
        }
    }

    func getWeekdayNewAnimes() async {
        let day = selectedWeekday
        do {
            let response = try await HomeAPIService.shared.getWeekdayNewAnimes(
                day: day.apiValue,
                sort: WeekdayNewAnimeSort.popular.apiValue,
                lastId: nil,
                size: 6
            )
            guard day == selectedWeekday else { return }
            weekdayNewAnimes = response.result?.animes ?? []
        } catch {
            DLog("weekday new anime - \(error.localizedDescription)")
        }
    }

    func selectWeekday(_ day: WeekdayNewAnimeDay) async {
        guard selectedWeekday != day else { return }
        selectedWeekday = day
        weekdayNewAnimes = []
        await getWeekdayNewAnimes()
    }
    
    func fetchRecommendationAnimeWithAnimeId() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        DLog("lastvisitedAnimeId - \(animeId)")
        session.request(HomeAPI.animeRecommendation(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation with animeid success \(value)")
                    if let animeList = value.result,
                       let recommend = animeList.animes {
                        self.recommendationAnimesWithAnimeId = recommend
                        self.recommendationTitle = animeList.referenceAnimeTitle ?? "--"
                    }
                case .failure(let error):
                    DLog("fetch home recommendation with animeid error \(error)")
                }
            }
    }
    
    
    var hasRecentSimilarAnime: Bool {
        return !recommendationFirstTitle.isEmpty && !recommendationSimilarAnimes.isEmpty
    }

    // TODO: 최근 찾아보신 작품과 비슷한 작품 -> 가장 최근에 들어간 작품 userdefaults로 정리해두어야함
    func fetchSimilarAnime() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        guard animeId != 0 else {
            self.recommendationSimilarAnimes = []
            self.recommendationFirstTitle = ""
            return
        }
        session.request(HomeAPI.animeRecommendation(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("fetch home recommendation with animeid success \(value)")
                    self.recommendationSimilarAnimes = value.result?.animes ?? []
                    self.recommendationFirstTitle = value.result?.referenceAnimeTitle ?? ""
                case .failure(let error):
                    DLog("fetch home recommendation with animeid error \(error)")
                }
            }
    }
    
    func moveToSearchView() {
        self.navigationManager.push(route: AppRoute.homeSearch)
    }
    
    func moveToExploreView(season: Int, year: Int) {
        AppDIContainer.appState.pushExplore(year: String(year), season: String(season))
        self.navigationManager.push(route: .content(activeTab: .research))
    }
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func moveToComingSoonView() {
        self.navigationManager.push(route: .comingSoonDetail)
    }
    
    func moveToRecentReviewView() {
        self.navigationManager.push(route: .recentReview)
    }
    
    func moveToRecommendationView(animeId: Int, animeTitle: String? = nil) {
        self.navigationManager.push(route: .recommend2(animeId: animeId, animeTitle: animeTitle))
    }
    
    func moveToSimilarRecommendationView() {
        let animeId = UserDefaultsManager.shared.getLastVisitedAnimeId()
        self.navigationManager.push(route: .recommendView(animeId: animeId))
    }
    
    func moveToRankingView() {
        self.navigationManager.push(route: .content(activeTab: .ranking))
    }

    func moveToWeekdayNewAnimeView() {
        navigationManager.push(route: .weekdayNewAnime(day: selectedWeekday.rawValue))
    }
}

enum WeekdayNewAnimeDay: Int, CaseIterable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        case .sunday: return "일"
        }
    }

    /// 서버 `GET api/animes`의 `day` 파라미터 (MON~SUN)
    var apiValue: String {
        switch self {
        case .monday: return "MON"
        case .tuesday: return "TUE"
        case .wednesday: return "WED"
        case .thursday: return "THU"
        case .friday: return "FRI"
        case .saturday: return "SAT"
        case .sunday: return "SUN"
        }
    }

    var previous: WeekdayNewAnimeDay? {
        return WeekdayNewAnimeDay(rawValue: rawValue - 1)
    }

    var next: WeekdayNewAnimeDay? {
        return WeekdayNewAnimeDay(rawValue: rawValue + 1)
    }

    static var today: WeekdayNewAnimeDay {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return WeekdayNewAnimeDay(rawValue: weekday == 1 ? 7 : weekday - 1) ?? .monday
    }
}

@MainActor
final class WeekdayNewAnimeViewModel: ObservableObject {
    @Published private(set) var animes: [Anime] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published private(set) var selectedDay: WeekdayNewAnimeDay
    @Published private(set) var selectedSort: WeekdayNewAnimeSort = .popular

    private let service = HomeAPIService.shared
    private let navigationManager: NavigationManager
    private var lastId: Int?
    private var hasLoaded = false

    init(day: Int, navigationManager: NavigationManager) {
        selectedDay = WeekdayNewAnimeDay(rawValue: day) ?? .today
        self.navigationManager = navigationManager
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    /// 선택한 요일·정렬로 첫 페이지를 다시 불러온다. 응답이 오기 전에 요일·정렬이 바뀌면 그 응답은 버린다.
    func reload() async {
        let day = selectedDay
        let sort = selectedSort
        isLoading = true
        isLoadingMore = false
        lastId = nil
        hasMore = true
        animes = []

        do {
            let response = try await service.getWeekdayNewAnimes(day: day.apiValue, sort: sort.apiValue, lastId: nil)
            guard isCurrent(day: day, sort: sort) else { return }
            append(response.result?.animes ?? [])
            updateCursor(response.result?.cursor?.lastId)
        } catch {
            DLog("weekday new anime load error - \(error.localizedDescription)")
        }
        if isCurrent(day: day, sort: sort) {
            isLoading = false
        }
    }

    func loadMoreIfNeeded(item: Anime) async {
        guard item.animeId == animes.last?.animeId,
              hasMore,
              !isLoading,
              !isLoadingMore else { return }
        guard let lastId else {
            hasMore = false
            return
        }

        let day = selectedDay
        let sort = selectedSort
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await service.getWeekdayNewAnimes(day: day.apiValue, sort: sort.apiValue, lastId: lastId)
            guard isCurrent(day: day, sort: sort) else { return }
            let newItems = response.result?.animes ?? []
            append(newItems)
            updateCursor(response.result?.cursor?.lastId)
            if newItems.isEmpty { hasMore = false }
        } catch {
            DLog("weekday new anime load more error - \(error.localizedDescription)")
        }
    }

    func select(day: WeekdayNewAnimeDay) async {
        guard selectedDay != day else { return }
        selectedDay = day
        await reload()
    }

    func select(sort: WeekdayNewAnimeSort) async {
        guard selectedSort != sort else { return }
        selectedSort = sort
        await reload()
    }

    func selectPreviousDay() async {
        guard let day = selectedDay.previous else { return }
        await select(day: day)
    }

    func selectNextDay() async {
        guard let day = selectedDay.next else { return }
        await select(day: day)
    }

    func tappedAnime(_ anime: Anime) {
        navigationManager.push(route: .animeDetail(animeId: anime.animeId ?? 0))
    }

    private func append(_ items: [Anime]) {
        let ids = Set(animes.compactMap { $0.animeId })
        animes.append(contentsOf: items.filter { anime in
            guard let id = anime.animeId else { return true }
            return !ids.contains(id)
        })
    }

    private func isCurrent(day: WeekdayNewAnimeDay, sort: WeekdayNewAnimeSort) -> Bool {
        return day == selectedDay && sort == selectedSort
    }

    private func updateCursor(_ newLastId: Int?) {
        if newLastId == nil || newLastId == lastId { hasMore = false }
        lastId = newLastId
    }
}

enum WeekdayNewAnimeSort: String, CaseIterable, Identifiable {
    case popular
    case latest

    var id: String { rawValue }
    var title: String { self == .popular ? "인기순" : "최신순" }

    /// 서버 `GET api/animes`의 `sort` 파라미터
    var apiValue: String {
        switch self {
        case .popular: return "popularity"
        case .latest: return "latest"
        }
    }
}
