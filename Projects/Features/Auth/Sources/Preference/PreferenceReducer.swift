import Analytics
import ExploreClientInterface
import MVICore
import MetadataClientInterface
import Navigation
import ReviewClientInterface

/// 가입 직후 취향 선택(온보딩). 동작 목록: notes/2026-10-30-R-auth-04-preference.md (PS1~PS14)
struct PreferenceReducer: Reducer {
    static let quarters = ["전체", "1", "2", "3", "4"]

    let exploreClient: any ExploreClient
    let reviewClient: any ReviewClient
    let metadataClient: any MetadataClient
    let analytics: any AnalyticsTracking
    let onLoginCompleted: @MainActor @Sendable () -> Void
    /// 처음 목록을 받기 전 기다림 (레거시 1초)
    var firstLoadDelay: Duration = .seconds(1)

    enum FilterTab: String, CaseIterable, Sendable {
        case yearQuarter = "년도/분기"
        case genre = "장르"
    }

    struct Rating: Equatable, Sendable {
        let animeId: Int
        var rating: Double
    }

    struct State: Equatable {
        var animes: [OnboardingAnime] = []
        var lastId: Int?
        var query = ""
        var selectedYear = ""
        var selectedQuarter = ""
        var selectedGenre = ""
        var selectedGenreId: Int?
        var filterTab = FilterTab.genre
        var isFilterSheetPresented = false
        /// 별점 입력줄이 열린 애니 (레거시 selectedAnimeList)
        var openedRatingIds: Set<Int> = []
        /// 매긴 별점 (매긴 순서, 같은 애니는 교체)
        var ratings: [Rating] = []
        var genres: [Genre]
        var seasonYears: [String]

        init(genres: [Genre], seasonYears: [String]) {
            self.genres = genres
            self.seasonYears = seasonYears
        }

        func rating(of animeId: Int) -> Double? {
            return ratings.first { $0.animeId == animeId }?.rating
        }
    }

    enum Intent: Sendable {
        case appeared
        case metadataRefreshed
        case firstLoadTimerFired
        case queryChanged(String)
        case searchRequested
        case clearSearchTapped
        case itemAppeared(OnboardingAnime)
        case pageLoaded(OnboardingPage)
        case filterChipTapped(FilterTab)
        case filterTabSelected(FilterTab)
        case yearChanged(String)
        case quarterChanged(String)
        case genreSelected(String)
        case filterResetTapped
        case filterDoneTapped
        case filterCloseTapped
        case filterSheetPresentedChanged(Bool)
        case animeTapped(Int)
        case ratingSubmitted(animeId: Int, rating: Double)
        case ratingChanged(animeId: Int, rating: Double)
        case ratingCancelTapped(Int)
        case doneTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 메타데이터를 다시 받고, 1초 뒤 목록을 받는다 (PS2)
            return .merge([
                .run { [metadataClient] in
                    await metadataClient.refresh()
                    return .metadataRefreshed
                },
                .run { [firstLoadDelay] in
                    try? await Task.sleep(for: firstLoadDelay)
                    return .firstLoadTimerFired
                },
            ])

        case .metadataRefreshed:
            state.genres = metadataClient.cachedGenres()
            state.seasonYears = metadataClient.cachedSeasonYears().map(String.init)
            return .none

        case .firstLoadTimerFired:
            return fetch(state)

        case .queryChanged(let query):
            state.query = query
            return .none

        case .searchRequested:
            // 제출하거나 검색창 포커스가 풀리면 처음부터 다시 받는다 (PS4)
            return search(&state)

        case .clearSearchTapped:
            state.query = ""
            return search(&state)

        case .itemAppeared(let anime):
            // 받는 중인지 보지 않는다 (PS3)
            guard anime.animeId == state.animes.last?.animeId else {
                return .none
            }
            return fetch(state)

        case .pageLoaded(let page):
            state.animes += page.animes
            state.lastId = page.lastId
            return .none

        case .filterChipTapped(let tab):
            state.filterTab = tab
            state.isFilterSheetPresented.toggle()
            return .none

        case .filterTabSelected(let tab):
            state.filterTab = tab
            return .none

        case .yearChanged(let year):
            state.selectedYear = year
            return .none

        case .quarterChanged(let quarter):
            state.selectedQuarter = quarter
            return .none

        case .genreSelected(let name):
            // 이름으로 id를 찾고, 못 찾으면 이전 id를 둔다 (레거시 그대로)
            if let id = state.genres.first(where: { $0.name == name })?.id {
                state.selectedGenreId = id
            }
            state.selectedGenre = name
            return .none

        case .filterResetTapped:
            state.selectedYear = ""
            state.selectedGenre = ""
            state.selectedQuarter = ""
            state.selectedGenreId = nil
            state.lastId = nil
            return .none

        case .filterDoneTapped:
            state.lastId = nil
            return toggleSheetAndReload(&state)

        case .filterCloseTapped:
            // 커서를 비우지 않은 채 목록만 비우고 다시 받는다 (레거시 그대로, PS6)
            return toggleSheetAndReload(&state)

        case .filterSheetPresentedChanged(let isPresented):
            state.isFilterSheetPresented = isPresented
            return .none

        case .animeTapped(let animeId):
            if state.openedRatingIds.contains(animeId) {
                state.openedRatingIds.remove(animeId)
            } else {
                state.openedRatingIds.insert(animeId)
            }
            return .none

        case .ratingSubmitted(let animeId, let rating):
            upsert(&state, animeId, rating)
            return reduce(into: &state, intent: .animeTapped(animeId))

        case .ratingChanged(let animeId, let rating):
            upsert(&state, animeId, rating)
            return .none

        case .ratingCancelTapped(let animeId):
            state.ratings.removeAll { $0.animeId == animeId }
            return .none

        case .doneTapped:
            // 보내기를 기다리지 않고 홈으로 간다. 화면이 사라져도 보내기는 끝까지 간다 (PS12)
            let ratings = state.ratings.map {
                InitialRating(animeId: $0.animeId, rating: $0.rating)
            }
            return .run { [reviewClient, analytics, onLoginCompleted] in
                Task {
                    try? await reviewClient.storeInitialRatings(ratings)
                }
                analytics.log(.onboardingComplete(ratedCount: ratings.count))
                await onLoginCompleted()
                return nil
            }
        }
    }

    private func upsert(_ state: inout State, _ animeId: Int, _ rating: Double) {
        if let index = state.ratings.firstIndex(where: { $0.animeId == animeId }) {
            state.ratings[index].rating = rating
        } else {
            state.ratings.append(Rating(animeId: animeId, rating: rating))
        }
    }

    private func search(_ state: inout State) -> Effect<Intent> {
        state.lastId = nil
        state.animes.removeAll()
        return fetch(state)
    }

    /// 레거시 `tappedModelView`: 시트를 토글하고 목록을 비운 뒤 다시 받는다
    private func toggleSheetAndReload(_ state: inout State) -> Effect<Intent> {
        state.isFilterSheetPresented.toggle()
        state.animes.removeAll()
        return fetch(state)
    }

    private func fetch(_ state: State) -> Effect<Intent> {
        let query = state.query.isEmpty ? nil : state.query
        let (year, season, genreId, lastId) = (
            Int(state.selectedYear), Int(state.selectedQuarter), state.selectedGenreId, state.lastId
        )
        return .run { [exploreClient] in
            guard
                let page = try? await exploreClient.onboardingAnimes(
                    query: query, year: year, season: season, genreId: genreId, lastId: lastId)
            else {
                return nil
            }
            return .pageLoaded(page)
        }
    }
}
