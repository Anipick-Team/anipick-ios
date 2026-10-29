import DetailClientInterface
import DetailInterface
import MVICore
import Navigation

/// 관련 작품·함께 볼만한 작품. 동작 목록: notes/2026-10-30-R-detail-01-series-recommendations.md (SD2~SD7, RC2~RC6)
struct AnimeListReducer: Reducer {
    let detailClient: any DetailClient
    let navigator: any Navigator

    enum Kind: Equatable, Sendable {
        /// 레거시 `SeriesDetailView`
        case series
        /// 레거시 `RecommendedView`
        case recommendations
    }

    struct State: Equatable {
        let kind: Kind
        let animeId: Int
        /// 함께 볼만한 작품은 받으면 기준 제목으로 바뀐다
        var animeTitle: String
        var items: [DetailAnime] = []
        var count = 0
        var lastId: Int?

        init(kind: Kind, animeId: Int, animeTitle: String) {
            self.kind = kind
            self.animeId = animeId
            self.animeTitle = animeTitle
        }

        var headerTitle: String {
            return kind == .series ? "관련 작품" : "함께 볼만한 작품"
        }

        var bannerText: String {
            switch kind {
            case .series:
                return "\(animeTitle) 의\n 관련 작품이에요!"
            case .recommendations:
                return "'\(animeTitle)'와\n 함께보기 좋은 작품"
            }
        }
    }

    enum Intent: Sendable {
        case appeared
        case itemAppeared(DetailAnime)
        case seriesLoaded(SeriesPage, replacing: Bool)
        case recommendationsLoaded(AnimeRecommendationPage)
        case itemTapped(DetailAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            switch state.kind {
            case .series:
                // 보일 때마다 커서를 비우고 첫 페이지로 바꾼다
                state.lastId = nil
                return fetchSeries(state, replacing: true)
            case .recommendations:
                // 보일 때마다 지금 커서로 이어 받는다
                return fetchRecommendations(state)
            }

        case .itemAppeared(let item):
            guard item == state.items.last else {
                return .none
            }
            // 커서가 없어도 받는다 (레거시 그대로)
            return state.kind == .series
                ? fetchSeries(state, replacing: false) : fetchRecommendations(state)

        case .seriesLoaded(let page, let replacing):
            state.items = replacing ? page.animes : state.items + page.animes
            state.count = page.count
            state.lastId = page.lastId
            return .none

        case .recommendationsLoaded(let page):
            // 이미 있는 animeId는 빼고 붙인다
            let existing = Set(state.items.map(\.animeId))
            state.items += page.animes.filter { !existing.contains($0.animeId) }
            state.lastId = page.lastId
            state.animeTitle = page.referenceAnimeTitle ?? "-"
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

    /// 결과가 없거나 실패하면 그대로 둔다
    private func fetchSeries(_ state: State, replacing: Bool) -> Effect<Intent> {
        let (animeId, lastId) = (state.animeId, state.lastId)
        return .run { [detailClient] in
            guard let page = try? await detailClient.series(animeId: animeId, lastId: lastId) else {
                return nil
            }
            return .seriesLoaded(page, replacing: replacing)
        }
    }

    private func fetchRecommendations(_ state: State) -> Effect<Intent> {
        let (animeId, lastId) = (state.animeId, state.lastId)
        return .run { [detailClient] in
            guard
                let page = try? await detailClient.recommendations(animeId: animeId, lastId: lastId)
            else {
                return nil
            }
            return .recommendationsLoaded(page)
        }
    }
}
