import DetailInterface
import HomeInterface
import MVICore
import MetadataClientInterface
import Navigation
import RankingClientInterface

/// 랭킹 탭. 동작 목록: notes/2026-10-29-R-ranking-01-ranking.md
struct RankingReducer: Reducer {
    static let genrePlaceholder = "장르"
    static let allSeasons = "전체 분기"
    static let seasons = [allSeasons, "1", "2", "3", "4"]
    /// 연도를 고르지 않았을 때 (레거시 TODO: "현재 최신 분기로 잡히도록")
    static let defaultYear = 2025

    let rankingClient: any RankingClient
    let metadataClient: any MetadataClient
    let navigator: any Navigator

    enum Filter: String, CaseIterable, Sendable {
        case realTime = "실시간"
        case yearSeason = "년도/분기"
        case allTime = "역대"
    }

    struct State: Equatable {
        var items: [RankedAnime] = []
        var filter = Filter.realTime
        /// 장르 이름. 고르지 않았으면 "장르"
        var selectedGenre = RankingReducer.genrePlaceholder
        var selectedYear = ""
        var selectedSeason = ""
        var isLoadingPage = false
        var lastId: Int?
        var lastValue: String?
        var lastRank: Int?

        var genres: [String]
        var seasonYears: [String] = []
        var isGenreSheetPresented = false
        var isYearSeasonSheetPresented = false
        /// 연도/분기 시트의 휠 선택값. 시트를 닫아도 남는다 (레거시 View @State)
        var pickerYear = ""
        var pickerSeason = ""

        init(genres: [String]) {
            self.genres = genres
        }

        /// 연도/분기 칩 문구. 분기를 "전체 분기"로 고르면 빈 값으로 저장되어 "2025/분기"가 된다 (레거시 그대로)
        var yearSeasonChipTitle: String {
            let year = selectedYear.isEmpty ? "년도" : selectedYear
            return "\(year)/\(selectedSeason)분기"
        }
    }

    enum PageKind: Sendable {
        case realTime, yearSeason, allTime
    }

    enum Intent: Sendable {
        case appeared
        case itemAppeared(RankedAnime)
        case pageLoaded(PageKind, RankingPage)
        case pageFailed
        case filterTapped(Filter)
        case searchTapped
        case itemTapped(RankedAnime)

        case genreButtonTapped
        case genreSheetPresentedChanged(Bool)
        case genreTapped(String)
        case genreResetTapped
        case genreDoneTapped

        case yearSeasonSheetPresentedChanged(Bool)
        case yearSeasonSheetAppeared
        case pickerYearChanged(String)
        case pickerSeasonChanged(String)
        case yearSeasonResetTapped
        case yearSeasonDoneTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            return state.items.isEmpty ? fetchFirstPage(&state) : .none

        case .itemAppeared(let item):
            // 마지막 줄이 보이면 다음 페이지 (R8)
            guard !state.isLoadingPage, item.animeId == state.items.last?.animeId else {
                return .none
            }
            return fetchMore(&state)

        case .pageLoaded(let kind, let page):
            state.isLoadingPage = false
            state.items.append(contentsOf: page.animes)
            state.lastId = page.lastId
            switch kind {
            case .realTime:
                state.lastValue = page.lastValue
            case .yearSeason, .allTime:
                state.lastRank = state.items.last?.rank
            }
            return .none

        case .pageFailed:
            state.isLoadingPage = false
            return .none

        case .filterTapped(let filter):
            state.filter = filter
            if filter == .yearSeason {
                state.isYearSeasonSheetPresented.toggle()
                state.seasonYears = metadataClient.cachedSeasonYears().map(String.init)
            }
            // 레거시 순서: 첫 페이지 요청 → 연도·분기 비우기. 요청에는 비우기 전 값이 실린다 (R3)
            let effect = fetchFirstPage(&state)
            state.selectedYear = ""
            state.selectedSeason = ""
            return effect

        case .searchTapped:
            return push(HomeRoute.search)

        case .itemTapped(let item):
            return push(DetailRoute.anime(id: item.animeId ?? 0))

        case .genreButtonTapped:
            state.isGenreSheetPresented.toggle()
            return .none

        case .genreSheetPresentedChanged(let isPresented):
            state.isGenreSheetPresented = isPresented
            return .none

        case .genreTapped(let genre):
            state.selectedGenre = genre
            return .none

        case .genreResetTapped:
            // 목록을 비우지 않고 다음 페이지를 이어 붙인다 (레거시 resetData, R9)
            state.selectedGenre = Self.genrePlaceholder
            return fetchMore(&state)

        case .genreDoneTapped:
            state.isGenreSheetPresented.toggle()
            return fetchFirstPage(&state)

        case .yearSeasonSheetPresentedChanged(let isPresented):
            state.isYearSeasonSheetPresented = isPresented
            return .none

        case .yearSeasonSheetAppeared:
            if state.pickerYear.isEmpty {
                state.pickerYear = state.seasonYears.first ?? ""
            }
            if state.pickerSeason.isEmpty {
                state.pickerSeason = Self.allSeasons
            }
            return .none

        case .pickerYearChanged(let year):
            state.pickerYear = year
            return .none

        case .pickerSeasonChanged(let season):
            state.pickerSeason = season
            return .none

        case .yearSeasonResetTapped:
            // 고른 값은 그대로 두고 다음 페이지를 이어 붙인다 (레거시 resetData, R10)
            return fetchMore(&state)

        case .yearSeasonDoneTapped:
            state.selectedYear = state.pickerYear
            state.selectedSeason = state.pickerSeason == Self.allSeasons ? "" : state.pickerSeason
            state.isYearSeasonSheetPresented.toggle()
            return fetchFirstPage(&state)
        }
    }

    /// 레거시 `fetchFirstPage`: 커서·목록을 비우고 지금 필터로 요청
    private func fetchFirstPage(_ state: inout State) -> Effect<Intent> {
        state.lastId = nil
        state.lastRank = nil
        state.lastValue = nil
        state.isLoadingPage = false
        state.items.removeAll()
        return fetchMore(&state)
    }

    /// 레거시 `resetData`·`loadMoreIfNeeded`: 지금 커서로 다음 페이지
    private func fetchMore(_ state: inout State) -> Effect<Intent> {
        let genre = state.selectedGenre == Self.genrePlaceholder ? nil : state.selectedGenre
        let lastId = state.lastId
        let lastRank = state.lastRank
        switch state.filter {
        case .realTime:
            // 실시간만 중복 요청을 막는다 (R5)
            guard !state.isLoadingPage else {
                return .none
            }
            state.isLoadingPage = true
            let lastValue = state.lastValue
            return load(.realTime) { client async throws in
                try await client.realTime(genre: genre, lastId: lastId, lastValue: lastValue)
            }
        case .yearSeason:
            let year = Int(state.selectedYear) ?? Self.defaultYear
            let season =
                state.selectedSeason.isEmpty || state.selectedSeason == Self.allSeasons
                ? nil : Int(state.selectedSeason)
            return load(.yearSeason) { client async throws in
                try await client.yearSeason(
                    year: year, season: season, genre: genre, lastId: lastId, lastRank: lastRank)
            }
        case .allTime:
            return load(.allTime) { client async throws in
                try await client.allTime(genre: genre, lastId: lastId, lastRank: lastRank)
            }
        }
    }

    private func load(
        _ kind: PageKind,
        _ request:
            @escaping @Sendable (any RankingClient) async throws ->
            RankingPage
    ) -> Effect<Intent> {
        return .run { [rankingClient] in
            do {
                return .pageLoaded(kind, try await request(rankingClient))
            } catch {
                return .pageFailed
            }
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
