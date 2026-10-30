import DetailClientInterface
import DetailInterface
import MVICore
import Navigation

/// 제작사 상세. 동작 목록: notes/2026-10-30-R-detail-02-producer-cast.md (PR2~PR7)
struct ProducerReducer: Reducer {
    let detailClient: any DetailClient
    let navigator: any Navigator

    /// 방영 연도 하나의 작품들
    struct YearGroup: Equatable, Sendable {
        let year: String
        var animes: [StudioAnime]
    }

    struct State: Equatable {
        let studioId: Int
        var studioName = ""
        var groups: [YearGroup] = []
        var lastId: Int?
        var lastValue: String?

        init(studioId: Int) {
            self.studioId = studioId
        }
    }

    enum Intent: Sendable {
        case appeared
        case animeAppeared(StudioAnime)
        case loaded(StudioPage)
        case animeTapped(StudioAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 지금 커서로 받아 합친다
            return fetch(state)

        case .animeAppeared(let anime):
            // 서버 커서(lastId)와 같은 작품이 보이면 다음 페이지
            guard state.lastId == (anime.animeId ?? 0) else {
                return .none
            }
            return fetch(state)

        case .loaded(let page):
            state.studioName = page.studioName
            state.groups = Self.merge(state.groups, page.animes)
            state.lastId = page.lastId
            state.lastValue = page.lastValue
            return .none

        case .animeTapped(let anime):
            return .run { [navigator] in
                await navigator.push(DetailRoute.anime(id: anime.animeId ?? 0))
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    private func fetch(_ state: State) -> Effect<Intent> {
        let (id, lastId, lastValue) = (state.studioId, state.lastId, state.lastValue)
        return .run { [detailClient] in
            guard
                let page = try? await detailClient.studio(
                    id: id, lastId: lastId, lastValue: lastValue)
            else {
                return nil
            }
            return .loaded(page)
        }
    }

    /// 레거시 `makeGroupProducerList`: 연도별로 묶고(이미 있는 animeId는 빼고, id 없는 작품은 그대로) 연도 내림차순
    static func merge(_ groups: [YearGroup], _ incoming: [StudioAnime]) -> [YearGroup] {
        var buckets = Dictionary(uniqueKeysWithValues: groups.map { ($0.year, $0.animes) })
        var seen = Set(groups.flatMap { $0.animes.compactMap(\.animeId) })
        for anime in incoming {
            var bucket = buckets[anime.seasonYear] ?? []
            if let id = anime.animeId {
                guard !seen.contains(id) else {
                    buckets[anime.seasonYear] = bucket
                    continue
                }
                seen.insert(id)
            }
            bucket.append(anime)
            buckets[anime.seasonYear] = bucket
        }
        return buckets.map { YearGroup(year: $0.key, animes: $0.value) }
            .sorted { (Int($0.year) ?? 0) > (Int($1.year) ?? 0) }
    }
}
