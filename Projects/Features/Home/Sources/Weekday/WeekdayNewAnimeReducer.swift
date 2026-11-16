import DetailInterface
import HomeClientInterface
import MVICore
import Navigation

/// 요일별 신작 (PR #18). 동작 목록: notes/2026-10-30-R-home-02-coming-soon-weekday.md (WN1~WN10)
struct WeekdayNewAnimeReducer: Reducer {
    let homeClient: any HomeClient
    let navigator: any Navigator

    enum Sort: String, CaseIterable, Identifiable, Sendable {
        case popular
        case latest

        var id: String {
            return rawValue
        }

        var title: String {
            return self == .popular ? "인기순" : "최신순"
        }

        /// 서버 `GET api/animes`의 `sort` 파라미터
        var apiValue: String {
            switch self {
            case .popular:
                return "popularity"
            case .latest:
                return "latest"
            }
        }
    }

    struct State: Equatable {
        var day: WeekdayNewAnimeDay
        var sort = Sort.popular
        var animes: [HomeAnime] = []
        var isLoading = false
        var isLoadingMore = false
        var hasMore = true
        var lastId: Int?
        var hasLoaded = false

        init(day: WeekdayNewAnimeDay) {
            self.day = day
        }
    }

    enum Intent: Sendable {
        case appeared
        case daySelected(WeekdayNewAnimeDay)
        case sortSelected(Sort)
        case swipedToPreviousDay
        case swipedToNextDay
        case itemAppeared(HomeAnime)
        case loaded(WeekdayNewAnimeDay, Sort, WeekdayAnimePage?)
        case moreLoaded(WeekdayNewAnimeDay, Sort, WeekdayAnimePage?)
        case itemTapped(HomeAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            guard !state.hasLoaded else {
                return .none
            }
            state.hasLoaded = true
            return reload(&state)

        case .daySelected(let day):
            guard day != state.day else {
                return .none
            }
            state.day = day
            return reload(&state)

        case .sortSelected(let sort):
            guard sort != state.sort else {
                return .none
            }
            state.sort = sort
            return reload(&state)

        case .swipedToPreviousDay:
            guard let day = state.day.previous else {
                return .none
            }
            return reduce(into: &state, intent: .daySelected(day))

        case .swipedToNextDay:
            guard let day = state.day.next else {
                return .none
            }
            return reduce(into: &state, intent: .daySelected(day))

        case .itemAppeared(let item):
            guard item.animeId == state.animes.last?.animeId, state.hasMore, !state.isLoading,
                !state.isLoadingMore
            else {
                return .none
            }
            guard let lastId = state.lastId else {
                state.hasMore = false
                return .none
            }
            state.isLoadingMore = true
            let (day, sort) = (state.day, state.sort)
            return .run { [homeClient] in
                let page = try? await homeClient.weekdayNewAnimes(
                    day: day.apiValue, sort: sort.apiValue, lastId: lastId, size: 18)
                return .moreLoaded(day, sort, page)
            }

        case .loaded(let day, let sort, let page):
            // 응답이 오기 전에 요일·정렬이 바뀌었으면 버린다
            guard day == state.day, sort == state.sort else {
                return .none
            }
            if let page {
                append(&state, page.animes)
                updateCursor(&state, page.lastId)
            }
            state.isLoading = false
            return .none

        case .moreLoaded(let day, let sort, let page):
            state.isLoadingMore = false
            guard day == state.day, sort == state.sort, let page else {
                return .none
            }
            append(&state, page.animes)
            updateCursor(&state, page.lastId)
            if page.animes.isEmpty {
                state.hasMore = false
            }
            return .none

        case .itemTapped(let item):
            return .run { [navigator] in
                await navigator.push(DetailRoute.anime(id: item.animeId ?? 0))
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 지금 요일·정렬로 첫 페이지를 다시 받는다
    private func reload(_ state: inout State) -> Effect<Intent> {
        state.isLoading = true
        state.isLoadingMore = false
        state.lastId = nil
        state.hasMore = true
        state.animes = []
        let (day, sort) = (state.day, state.sort)
        return .run { [homeClient] in
            let page = try? await homeClient.weekdayNewAnimes(
                day: day.apiValue, sort: sort.apiValue, lastId: nil, size: 18)
            return .loaded(day, sort, page)
        }
    }

    /// id가 있는 작품은 겹치지 않게 붙인다 (id가 없는 작품은 그대로 붙인다)
    private func append(_ state: inout State, _ items: [HomeAnime]) {
        let ids = Set(state.animes.compactMap(\.animeId))
        state.animes += items.filter { anime in
            guard let id = anime.animeId else {
                return true
            }
            return !ids.contains(id)
        }
    }

    /// 커서가 없거나 그대로면 더 받을 것이 없다
    private func updateCursor(_ state: inout State, _ lastId: Int?) {
        if lastId == nil || lastId == state.lastId {
            state.hasMore = false
        }
        state.lastId = lastId
    }
}
