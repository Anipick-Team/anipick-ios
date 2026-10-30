import DetailInterface
import MVICore
import MyInfoClientInterface
import Navigation

/// 볼·보는 중·다 본 애니 목록. 동작 목록: notes/2026-10-29-R-myinfo-01-lists.md (W1~W8)
struct WatchListReducer: Reducer {
    let status: WatchStatus
    let myInfoClient: any MyInfoClient
    let navigator: any Navigator

    struct State: Equatable {
        let status: WatchStatus
        var count = 0
        var items: [MyAnime] = []
        var lastId: Int?

        var title: String {
            switch status {
            case .watchList:
                return "볼 애니"
            case .watching:
                return "보는 중"
            case .finished:
                return "다 본 애니"
            }
        }

        var emptyMessage: String {
            switch status {
            case .watchList:
                return "아직 볼 애니가 없어요!"
            case .watching:
                return "아직 보는 중인 작품이 없어요!"
            case .finished:
                return "아직 다 본 작품이 없어요!"
            }
        }
    }

    enum Intent: Sendable {
        case appeared
        case itemAppeared(MyAnime)
        case pageLoaded(MyPage<MyAnime>)
        case itemTapped(MyAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 지금 커서로 다음 페이지를 받는다 — 상세에서 돌아와도 (W3)
            return fetch(lastId: state.lastId)

        case .itemAppeared(let item):
            // 받는 중인지 보지 않는다 (W4)
            guard item.animeId == state.items.last?.animeId else {
                return .none
            }
            return fetch(lastId: state.lastId)

        case .pageLoaded(let page):
            state.count = page.count
            state.items.append(contentsOf: page.items)
            state.lastId = page.lastId
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

    private func fetch(lastId: Int?) -> Effect<Intent> {
        return .run { [myInfoClient, status] in
            guard let page = try? await myInfoClient.watchList(status, lastId: lastId) else {
                return nil
            }
            return .pageLoaded(page)
        }
    }
}
