import DetailClientInterface
import DetailInterface
import MVICore
import Navigation

/// 성우 상세. 동작 목록: notes/2026-10-30-R-detail-03-voice-actor.md (VA2~VA7)
struct VoiceActorReducer: Reducer {
    let detailClient: any DetailClient
    let navigator: any Navigator

    struct State: Equatable {
        let personId: Int
        var imageUrl = ""
        var name = ""
        var workCount = 0
        var works: [PersonWork] = []
        var isLiked = false
        var lastId: Int?
        var didStart = false

        init(personId: Int) {
            self.personId = personId
        }
    }

    enum Intent: Sendable {
        case appeared
        case workAppeared(PersonWork)
        case loaded(PersonPage)
        case likeTapped
        case workTapped(PersonWork)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 레거시는 ViewModel을 만들 때 한 번 받는다
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            return fetch(state)

        case .workAppeared(let work):
            // 마지막 배역이 보이면 다음 페이지 (끝인지는 보지 않는다)
            guard work.characterId == state.works.last?.characterId else {
                return .none
            }
            return fetch(state)

        case .loaded(let page):
            state.imageUrl = page.profileImageUrl ?? ""
            state.name = page.name
            state.workCount = page.count
            state.works += page.works
            state.isLiked = page.isLiked
            state.lastId = page.lastId
            return .none

        case .likeTapped:
            // 화면을 먼저 바꾸고 요청한다. 실패해도 되돌리지 않는다 (레거시 그대로)
            let liked = !state.isLiked
            state.isLiked = liked
            let personId = state.personId
            return .run { [detailClient] in
                try? await detailClient.setPersonLike(id: personId, liked: liked)
                return nil
            }

        case .workTapped(let work):
            return .run { [navigator] in
                await navigator.push(DetailRoute.anime(id: work.animeId))
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
        let (personId, lastId) = (state.personId, state.lastId)
        return .run { [detailClient] in
            guard let page = try? await detailClient.person(id: personId, lastId: lastId) else {
                return nil
            }
            return .loaded(page)
        }
    }
}
