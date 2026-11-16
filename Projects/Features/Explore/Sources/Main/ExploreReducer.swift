import DetailInterface
import ExploreInterface
import ExploreClientInterface
import Foundation
import HomeInterface
import MVICore
import MetadataClientInterface
import Navigation

/// 탐색 탭 (작품 탐색 | 커뮤니티). 동작 목록: notes/2026-10-30-R-explore-02-main.md (EX1~EX16)
struct ExploreReducer: Reducer {
    static let quarters = ["전체", "1", "2", "3", "4"]

    let exploreClient: any ExploreClient
    let metadataClient: any MetadataClient
    let navigator: any Navigator
    /// 홈의 "곧 방영" 등에서 넘겨 둔 연도·분기를 꺼낸다 (꺼내면 비운다)
    let consumePendingFilter: @MainActor @Sendable () -> PendingExploreFilter?
    /// 필터 칩을 누른 뒤 시트를 띄우기까지 (레거시 0.5초)
    var sheetDelay: Duration = .milliseconds(500)

    enum MainTab: String, CaseIterable, Sendable {
        case anime = "작품 탐색"
        case community = "커뮤니티"
    }

    enum FilterTab: String, CaseIterable, Sendable {
        case yearQuarter = "년도/분기"
        case season = "분기"
        case genre = "장르"
        case type = "타입"
    }

    enum Sort: String, CaseIterable, Sendable {
        case popularity
        case rating

        var title: String {
            switch self {
            case .popularity:
                return "인기순"
            case .rating:
                return "평점순"
            }
        }
    }

    /// 선택한 조건 칩 (레거시 `ExploreSelectedTag`). 같은 종류·값은 하나만 둔다
    struct Tag: Hashable, Sendable {
        let category: FilterTab
        let value: String

        /// 분기는 "N분기", 단 "전체 분기"는 그대로
        var title: String {
            guard category == .season else {
                return value
            }
            return value + (value == "전체 분기" ? "" : "분기")
        }
    }

    struct State: Equatable {
        var mainTab = MainTab.anime
        var items: [ExploreAnime] = []
        var lastId: Int?
        var tags: [Tag] = []
        var sort = Sort.popularity
        var isSortMenuPresented = false
        var matchesAllGenres = false
        var filterTab = FilterTab.yearQuarter
        var isFilterSheetPresented = false
        var pickerYear = ""
        var pickerSeason = ""
        var pickedGenres: [String] = []
        /// 시트에서 선택 표시하는 장르 (레거시 selectedGenreListForUI — 완료해도 남는다)
        var highlightedGenres: [String] = []
        var pickerType = ""
        var genres: [String]
        var years: [String]
        var types: [String]

        init(genres: [String], years: [String], types: [String]) {
            self.genres = genres
            self.years = years
            self.types = types
        }

        /// 시트의 지금 탭 목록
        var currentOptions: [String] {
            switch filterTab {
            case .yearQuarter:
                return years
            case .genre:
                return genres
            case .type:
                return types
            case .season:
                return ["전체 분기", "1분기", "2분기", "3분기", "4분기"]
            }
        }

        func hasTag(_ category: FilterTab) -> Bool {
            return tags.contains { $0.category == category }
        }
    }

    enum Intent: Sendable {
        case appeared
        case metadataRefreshed
        case pendingFilterChanged
        case mainTabSelected(MainTab)
        case filterChipTapped(FilterTab)
        case presentFilterSheet
        case filterSheetPresentedChanged(Bool)
        case filterTabSelected(FilterTab)
        case filterSheetAppeared
        case pickerYearChanged(String)
        case pickerSeasonChanged(String)
        case genreToggled(String)
        case matchAllGenresTapped
        case typeSelected(String)
        case filterResetTapped
        case filterDoneTapped
        case filterCloseTapped
        case tagRemoved(Tag)
        case sortButtonTapped
        case sortSelected(Sort)
        case itemAppeared(ExploreAnime)
        case pageLoaded(ExplorePage, replacing: Bool)
        case itemTapped(ExploreAnime)
        case searchTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 메타데이터가 하나라도 비었으면 다시 받는다. 넘겨받은 조건이 있으면 그것으로 처음부터, 없으면 지금 커서로 이어 받는다 (EX1)
            let refresh: Effect<Intent> =
                state.genres.isEmpty || state.years.isEmpty || state.types.isEmpty
                ? .run { [metadataClient] in
                    await metadataClient.refresh()
                    return .metadataRefreshed
                }
                : .none
            let load = applyPendingFilter(&state) ?? fetchMore(state)
            return .merge([refresh, load])

        case .metadataRefreshed:
            state.genres = metadataClient.cachedGenres().map(\.name)
            state.years = metadataClient.cachedSeasonYears().map(String.init)
            state.types = metadataClient.cachedTypes()
            return .none

        case .pendingFilterChanged:
            return applyPendingFilter(&state) ?? .none

        case .mainTabSelected(let tab):
            state.mainTab = tab
            return .none

        case .filterChipTapped(let tab):
            // 탭이 바뀌면 바로, 같은 탭이면 0.5초 뒤 시트를 띄운다 (레거시 onChange + asyncAfter, EX3)
            if tab != state.filterTab {
                state.filterTab = tab
                state.isFilterSheetPresented = true
            }
            return .run { [sheetDelay] in
                try? await Task.sleep(for: sheetDelay)
                return .presentFilterSheet
            }

        case .presentFilterSheet:
            state.isFilterSheetPresented = true
            return .none

        case .filterSheetPresentedChanged(let isPresented):
            state.isFilterSheetPresented = isPresented
            return .none

        case .filterTabSelected(let tab):
            state.filterTab = tab
            state.isFilterSheetPresented = true
            return .none

        case .filterSheetAppeared:
            if state.pickerSeason.isEmpty {
                state.pickerSeason = Self.quarters.first ?? "전체 분기"
            }
            if state.filterTab == .yearQuarter, state.pickerYear.isEmpty {
                state.pickerYear = state.currentOptions.first ?? ""
            }
            return .none

        case .pickerYearChanged(let year):
            state.pickerYear = year
            return .none

        case .pickerSeasonChanged(let season):
            state.pickerSeason = season
            return .none

        case .genreToggled(let genre):
            if state.pickedGenres.contains(genre) {
                state.pickedGenres.removeAll { $0 == genre }
                state.highlightedGenres.removeAll { $0 == genre }
            } else {
                state.pickedGenres.append(genre)
                state.highlightedGenres.append(genre)
            }
            return .none

        case .matchAllGenresTapped:
            state.matchesAllGenres.toggle()
            return .none

        case .typeSelected(let type):
            state.pickerType = type
            return .none

        case .filterResetTapped:
            // 조건·커서와 시트 선택을 비운다. 다시 받지는 않는다 (EX8)
            state.tags.removeAll()
            state.lastId = nil
            state.highlightedGenres.removeAll()
            state.pickerType = ""
            state.pickerYear = ""
            state.pickerSeason = ""
            return .none

        case .filterDoneTapped:
            switch state.filterTab {
            case .yearQuarter:
                if !state.pickerYear.isEmpty {
                    replaceTag(&state, Tag(category: .yearQuarter, value: state.pickerYear))
                }
                if !state.pickerSeason.isEmpty {
                    replaceTag(&state, Tag(category: .season, value: state.pickerSeason))
                }
            case .genre:
                for genre in state.pickedGenres {
                    insertTag(&state, Tag(category: .genre, value: genre))
                }
            case .type:
                if !state.pickerType.isEmpty {
                    replaceTag(&state, Tag(category: .type, value: state.pickerType))
                }
            case .season:
                break
            }
            state.pickedGenres.removeAll()
            state.isFilterSheetPresented.toggle()
            return fetchFirst(&state)

        case .filterCloseTapped:
            state.isFilterSheetPresented.toggle()
            return .none

        case .tagRemoved(let tag):
            state.tags.removeAll { $0 == tag }
            if tag.category == .genre {
                state.highlightedGenres.removeAll { $0 == tag.value }
            }
            if tag.category == .yearQuarter {
                state.tags.removeAll { $0.category == .yearQuarter || $0.category == .season }
            }
            return fetchFirst(&state)

        case .sortButtonTapped:
            state.isSortMenuPresented.toggle()
            return .none

        case .sortSelected(let sort):
            state.sort = sort
            state.lastId = nil
            state.items = []
            state.isSortMenuPresented.toggle()
            return fetchFirst(&state)

        case .itemAppeared(let item):
            guard item == state.items.last else {
                return .none
            }
            return fetchMore(state)

        case .pageLoaded(let page, let replacing):
            if replacing {
                state.items = page.animes
            } else {
                let existing = Set(state.items.map(\.animeId))
                state.items += page.animes.filter { !existing.contains($0.animeId) }
            }
            state.lastId = page.lastId
            return .none

        case .itemTapped(let item):
            return push(DetailRoute.anime(id: item.animeId ?? 0))

        case .searchTapped:
            return push(HomeRoute.search)
        }
    }

    /// 넘겨받은 연도·분기를 칩으로 넣고 처음부터 받는다. 넘겨받은 것이 없으면 nil
    private func applyPendingFilter(_ state: inout State) -> Effect<Intent>? {
        guard let filter = consumePendingFilter() else {
            return nil
        }
        if let year = filter.year, !year.isEmpty {
            insertTag(&state, Tag(category: .yearQuarter, value: year))
        }
        if let season = filter.season, !season.isEmpty {
            insertTag(&state, Tag(category: .season, value: season))
        }
        return fetchFirst(&state)
    }

    private func insertTag(_ state: inout State, _ tag: Tag) {
        if !state.tags.contains(tag) {
            state.tags.insert(tag, at: 0)
        }
    }

    private func replaceTag(_ state: inout State, _ tag: Tag) {
        state.tags.removeAll { $0.category == tag.category }
        state.tags.insert(tag, at: 0)
    }

    /// 레거시 `fetchInitFilteredExploreData`: 목록을 비우고 커서 없이 받아 바꾼다
    private func fetchFirst(_ state: inout State) -> Effect<Intent> {
        state.items.removeAll()
        return load(query(state, lastId: nil), replacing: true)
    }

    /// 레거시 `fetchFilteredExploreData`: 지금 커서로 받아 이어 붙인다 (받는 중인지 보지 않음)
    private func fetchMore(_ state: State) -> Effect<Intent> {
        return load(query(state, lastId: state.lastId), replacing: false)
    }

    private func query(_ state: State, lastId: Int?) -> ExploreQuery {
        let genreNames = state.tags.filter { $0.category == .genre }.map(\.value)
        let genreIds =
            genreNames.isEmpty
            ? nil
            : metadataClient.cachedGenres().filter { genreNames.contains($0.name) }.map(\.id)
        return ExploreQuery(
            sort: state.sort.rawValue,
            year: state.tags.first { $0.category == .yearQuarter }.flatMap { Int($0.value) },
            season: state.tags.first { $0.category == .season }.flatMap { Int($0.value) },
            genreIds: genreIds,
            type: state.tags.first { $0.category == .type }?.value,
            lastId: lastId,
            genreOp: state.matchesAllGenres ? "AND" : "OR"
        )
    }

    private func load(_ query: ExploreQuery, replacing: Bool) -> Effect<Intent> {
        return .run { [exploreClient] in
            guard let page = try? await exploreClient.exploreAnimes(query) else {
                return nil
            }
            return .pageLoaded(page, replacing: replacing)
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
