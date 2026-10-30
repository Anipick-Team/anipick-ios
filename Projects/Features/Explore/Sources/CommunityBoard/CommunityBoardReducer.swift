import CommunityClientInterface
import ExploreInterface
import MVICore
import Navigation

/// 애니 커뮤니티 게시판. 동작 목록: notes/2026-10-30-R-explore-04-community-board.md (CP1~CP12)
struct CommunityBoardReducer: Reducer {
    let communityClient: any CommunityClient
    let navigator: any Navigator

    enum Filter: String, CaseIterable, Sendable {
        case all = "전체"
        case monthly = "월간"
        case weekly = "주간"
        case daily = "일간"

        var sort: String {
            switch self {
            case .all:
                return "latest"
            case .monthly:
                return "popularMonthly"
            case .weekly:
                return "popularWeekly"
            case .daily:
                return "popularDaily"
            }
        }
    }

    struct State: Equatable {
        let seriesId: Int
        let animeTitle: String
        let coverImageUrl: String?
        let genreNames: [String]
        var posts: [CommunityPost] = []
        var filter = Filter.all
        var showsSpoilers = true
        var isLoading = false
        var hasNextPage = true
        var errorMessage: String?
        var lastId: Int?
        var lastValue: String?

        init(seriesId: Int, animeTitle: String, coverImageUrl: String?, genreNames: [String]) {
            self.seriesId = seriesId
            self.animeTitle = animeTitle
            self.coverImageUrl = coverImageUrl
            self.genreNames = genreNames
        }

        /// 스포일러를 끄면 화면에서만 뺀다
        var visiblePosts: [CommunityPost] {
            return posts.filter { showsSpoilers || !$0.isSpoiler }
        }
    }

    enum Intent: Sendable {
        case appeared
        case filterSelected(Filter)
        case spoilerToggled
        case retryTapped
        case postAppeared(CommunityPost)
        case loaded(CommunityPostPage, reset: Bool)
        case loadFailed
        case postTapped(CommunityPost)
        case writeTapped
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared, .retryTapped:
            // 보일 때마다 처음부터 (받는 중이면 건너뛴다)
            return fetch(&state, reset: true)

        case .filterSelected(let filter):
            guard filter != state.filter else {
                return .none
            }
            state.filter = filter
            return fetch(&state, reset: true)

        case .spoilerToggled:
            state.showsSpoilers.toggle()
            return .none

        case .postAppeared(let post):
            // 마지막 글(스포일러로 숨긴 글 포함)이 보일 때만 이어 받는다
            guard post.id == state.posts.last?.id else {
                return .none
            }
            return fetch(&state, reset: false)

        case .loaded(let page, let reset):
            state.posts = reset ? page.posts : state.posts + page.posts
            state.lastId = page.lastId
            state.lastValue = page.lastValue
            state.hasNextPage = !page.posts.isEmpty && page.lastId != nil
            state.isLoading = false
            return .none

        case .loadFailed:
            state.isLoading = false
            state.errorMessage = "게시글을 불러오지 못했습니다."
            return .none

        case .postTapped(let post):
            return push(ExploreRoute.communityPost(id: post.id))

        case .writeTapped:
            return push(
                ExploreRoute.communityWrite(seriesId: state.seriesId, animeTitle: state.animeTitle))

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 레거시 `fetchPosts(reset:)`: 받는 중이거나 다음 페이지가 없으면 건너뛴다. 처음부터 받을 때는 커서를 비운다
    private func fetch(_ state: inout State, reset: Bool) -> Effect<Intent> {
        guard !state.isLoading, reset || state.hasNextPage else {
            return .none
        }
        if reset {
            state.lastId = nil
            state.lastValue = nil
            state.hasNextPage = true
        }
        state.isLoading = true
        state.errorMessage = nil
        let (seriesId, sort, lastValue, lastId) = (
            state.seriesId, state.filter.sort, state.lastValue, state.lastId
        )
        return .run { [communityClient] in
            guard
                let page = try? await communityClient.posts(
                    seriesId: seriesId, sort: sort, lastValue: lastValue, lastId: lastId)
            else {
                return .loadFailed
            }
            return .loaded(page, reset: reset)
        }
    }

    private func push(_ route: ExploreRoute) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
