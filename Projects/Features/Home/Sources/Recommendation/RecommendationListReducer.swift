import DetailInterface
import HomeClientInterface
import MVICore
import Navigation

/// 추천 목록 두 화면 (취향 추천·비슷한 작품). 동작 목록: notes/2026-10-30-R-home-01-recommendations.md (RL1~RL10)
struct RecommendationListReducer: Reducer {
    let homeClient: any HomeClient
    let navigator: any Navigator

    enum Kind: Equatable, Sendable {
        /// 레거시 `RecommendedAnimeView`. 제목이 없으면 닉네임 문구
        case forYou(animeTitle: String?)
        /// 레거시 `SimilarRecommendedAnimeView`
        case similar(animeId: Int?)
    }

    struct State: Equatable {
        let kind: Kind
        let nickname: String
        var items: [HomeAnime] = []
        var lastId: Int?
        var lastValue: String?
        var referenceTitle = ""

        init(kind: Kind, nickname: String) {
            self.kind = kind
            self.nickname = nickname
        }

        var bannerText: String {
            switch kind {
            case .forYou(let animeTitle?):
                return "\(animeTitle) 을 재밌게 보셨다면,\n이 작품들도 마음에 드실거에요!"
            case .forYou(nil):
                return "오늘의 추천작, \(nickname) 님의\n취향에 맞춰 준비했어요!"
            case .similar:
                return "최근 찾아보신 \(referenceTitle)과\n비슷한 작품이에요"
            }
        }
    }

    enum Intent: Sendable {
        case appeared
        case itemAppeared(HomeAnime)
        case loaded(RecommendationPage)
        case itemTapped(HomeAnime)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 지금 커서로 받는다 (상세에서 돌아와도)
            return fetch(state)

        case .itemAppeared(let item):
            guard item.animeId ?? 0 == state.items.last?.animeId else {
                return .none
            }
            return fetch(state)

        case .loaded(let page):
            switch state.kind {
            case .forYou:
                // 취향 추천은 다음 페이지로 목록을 바꾼다 (레거시 그대로)
                state.items = page.animes
                state.lastId = page.lastId
            case .similar(let animeId):
                state.items += page.animes
                state.referenceTitle = page.referenceAnimeTitle ?? "--"
                state.lastId = page.lastId
                // 기준 작품이 없으면 lastValue를 갱신하지 않는다 (레거시 그대로)
                if animeId != nil {
                    state.lastValue = page.lastValue
                }
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

    /// 응답에 결과·목록이 없거나 실패하면 아무것도 바꾸지 않는다
    private func fetch(_ state: State) -> Effect<Intent> {
        let (kind, lastId, lastValue) = (state.kind, state.lastId, state.lastValue)
        return .run { [homeClient] in
            let page: RecommendationPage??
            switch kind {
            case .forYou:
                // 취향 추천은 lastValue를 보내지 않는다
                page = try? await homeClient.recommendations(lastId: lastId, lastValue: nil)
            case .similar(let animeId?):
                page = try? await homeClient.recentRecommendations(
                    animeId: animeId, lastId: lastId, lastValue: lastValue)
            case .similar(nil):
                page = try? await homeClient.recommendations(lastId: lastId, lastValue: lastValue)
            }
            guard let page = page ?? nil else {
                return nil
            }
            return .loaded(page)
        }
    }
}
