import DetailInterface
import HomeClientInterface
import MVICore
import Navigation

/// 공개 예정 목록. 동작 목록: notes/2026-10-30-R-home-02-coming-soon-weekday.md (CS1~CS8)
struct ComingSoonReducer: Reducer {
    let homeClient: any HomeClient
    let navigator: any Navigator

    enum Sort: String, CaseIterable, Sendable {
        case latest
        case popularity
        case startDate

        var title: String {
            switch self {
            case .latest:
                return "최신순"
            case .popularity:
                return "인기순"
            case .startDate:
                return "방영 예정 순"
            }
        }
    }

    struct State: Equatable {
        var items: [ComingSoonAnime] = []
        var sort = Sort.latest
        var isSortMenuPresented = false
        /// 19세 토글은 화면에서 막혀 있어 늘 false다 (레거시 그대로)
        var includesAdult = false
        var lastId: Int?
    }

    enum Intent: Sendable {
        case appeared
        case itemAppeared(ComingSoonAnime)
        case loaded(ComingSoonPage, isMore: Bool)
        case sortButtonTapped
        case sortSelected(Sort)
        case itemTapped(ComingSoonAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 첫 페이지를 받아 목록을 바꾼다
            return fetch(state, lastId: nil)

        case .itemAppeared(let item):
            guard item == state.items.last, let lastId = state.lastId else {
                return .none
            }
            return fetch(state, lastId: lastId)

        case .loaded(let page, let isMore):
            if isMore {
                // 이미 있는 animeId는 빼고 붙인다
                let existing = Set(state.items.map(\.animeId))
                state.items += page.animes.filter { !existing.contains($0.animeId) }
            } else {
                state.items = page.animes
            }
            state.lastId = page.lastId
            return .none

        case .sortButtonTapped:
            state.isSortMenuPresented.toggle()
            return .none

        case .sortSelected(let sort):
            state.sort = sort
            state.isSortMenuPresented.toggle()
            state.items.removeAll()
            return fetch(state, lastId: nil)

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

    /// 실패하거나 목록이 없으면 아무것도 바꾸지 않는다. 받는 중인지는 보지 않는다
    private func fetch(_ state: State, lastId: Int?) -> Effect<Intent> {
        let (sort, includesAdult) = (state.sort.rawValue, state.includesAdult)
        return .run { [homeClient] in
            guard
                let page = try? await homeClient.comingSoon(
                    sort: sort, lastId: lastId, includeAdult: includesAdult)
            else {
                return nil
            }
            return .loaded(page, isMore: lastId != nil)
        }
    }
}
