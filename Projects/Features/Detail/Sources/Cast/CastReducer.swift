import DetailClientInterface
import DetailInterface
import MVICore
import Navigation

/// 캐릭터·성우진. 동작 목록: notes/2026-10-30-R-detail-02-producer-cast.md (CV2~CV5)
struct CastReducer: Reducer {
    let detailClient: any DetailClient
    let navigator: any Navigator

    struct State: Equatable {
        let animeId: Int
        var cast: [CastMember] = []
        var didStart = false

        init(animeId: Int) {
            self.animeId = animeId
        }
    }

    enum Intent: Sendable {
        case appeared
        case loaded([CastMember])
        case memberTapped(CastMember)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 레거시는 ViewModel을 만들 때 한 번 받는다 (더 받지 않는다)
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            let animeId = state.animeId
            return .run { [detailClient] in
                guard let cast = try? await detailClient.characters(animeId: animeId) else {
                    return nil
                }
                return .loaded(cast)
            }

        case .loaded(let cast):
            state.cast = cast
            return .none

        case .memberTapped(let member):
            return .run { [navigator] in
                await navigator.push(DetailRoute.voiceActor(id: member.voiceActor?.id ?? 0))
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
