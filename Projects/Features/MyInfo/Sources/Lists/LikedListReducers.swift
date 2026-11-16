import DetailInterface
import MVICore
import MyInfoClientInterface
import Navigation

/// 좋아요한 작품. 동작 목록 LA1~LA4
struct LikedAnimesReducer: Reducer {
    let myInfoClient: any MyInfoClient
    let navigator: any Navigator

    struct State: Equatable {
        var count = 0
        var items: [MyAnime] = []
        var lastId: Int?
        var didLoad = false
    }

    enum Intent: Sendable {
        /// 레거시는 ViewModel을 만들 때 한 번 받는다. 상세에서 돌아와도 다시 받지 않는다 (LA1)
        case appeared
        case pageLoaded(MyPage<MyAnime>)
        case itemTapped(MyAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            guard !state.didLoad else {
                return .none
            }
            state.didLoad = true
            let lastId = state.lastId
            return .run { [myInfoClient] in
                guard let page = try? await myInfoClient.likedAnimes(lastId: lastId) else {
                    return nil
                }
                return .pageLoaded(page)
            }

        case .pageLoaded(let page):
            // 이어 붙이지 않고 바꾼다. 다음 페이지를 받는 곳은 없다 (LA2)
            state.items = page.items
            state.lastId = page.lastId
            state.count = page.count
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
}

/// 좋아요한 인물. 동작 목록 LP1~LP4
struct LikedPersonsReducer: Reducer {
    let myInfoClient: any MyInfoClient
    let navigator: any Navigator

    struct State: Equatable {
        var count = 0
        var items: [MyPerson] = []
        var lastId: Int?
        var didLoad = false
    }

    enum Intent: Sendable {
        /// 처음 한 번만 (LP1)
        case appeared
        case itemAppeared(MyPerson)
        case pageLoaded(MyPage<MyPerson>)
        case itemTapped(MyPerson)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            guard !state.didLoad else {
                return .none
            }
            state.didLoad = true
            return fetch(lastId: state.lastId)

        case .itemAppeared(let person):
            // 마지막 사람이 보이면 다음 페이지. 받는 중인지 보지 않는다 (LP2)
            guard person.personId ?? 0 == state.items.last?.personId else {
                return .none
            }
            return fetch(lastId: state.lastId)

        case .pageLoaded(let page):
            state.items.append(contentsOf: page.items)
            state.count = page.count
            state.lastId = page.lastId
            return .none

        case .itemTapped(let person):
            return .run { [navigator] in
                await navigator.push(DetailRoute.voiceActor(id: person.personId ?? 0))
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
        return .run { [myInfoClient] in
            guard let page = try? await myInfoClient.likedPersons(lastId: lastId) else {
                return nil
            }
            return .pageLoaded(page)
        }
    }
}
