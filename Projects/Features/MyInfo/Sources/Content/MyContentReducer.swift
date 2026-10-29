import ExploreInterface
import MVICore
import MyInfoClientInterface
import MyInfoInterface
import Navigation

/// 내 콘텐츠(내 게시글·내 댓글). 동작 목록: notes/2026-10-29-R-myinfo-03-content.md (MC1~MC10)
struct MyContentReducer: Reducer {
    let myInfoClient: any MyInfoClient
    let navigator: any Navigator
    let openTab: @MainActor @Sendable (MainTab) -> Void

    enum Tab: String, CaseIterable, Sendable {
        case posts = "내 게시글"
        case comments = "내 댓글"
    }

    struct State: Equatable {
        var tab = Tab.posts
        var posts: [MyPost] = []
        var comments: [MyComment] = []
        /// 두 탭이 함께 쓴다 (레거시 그대로)
        var totalCount = 0
        var isLoading = false
        var postLastId: Int?
        var commentLastId: Int?

        /// 999개를 넘으면 "999+" (MC4)
        var totalCountText: String {
            return totalCount > 999 ? "999+" : "\(totalCount)"
        }
    }

    enum Intent: Sendable {
        case appeared
        case tabSelected(Tab)
        case postAppeared(MyPost)
        case commentAppeared(MyComment)
        case postsLoaded(ContentPage<MyPost>)
        case commentsLoaded(ContentPage<MyComment>)
        case loadFailed
        case postTapped(MyPost)
        case commentTapped(MyComment)
        case mainTabTapped(MainTab)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 지금 탭을 처음부터 다시 받는다 (MC2)
            return fetch(&state, tab: state.tab, reset: true)

        case .tabSelected(let tab):
            guard tab != state.tab else {
                return .none
            }
            state.tab = tab
            return fetch(&state, tab: tab, reset: true)

        case .postAppeared(let post):
            guard post.postId == state.posts.last?.postId, state.postLastId != nil else {
                return .none
            }
            return fetch(&state, tab: .posts, reset: false)

        case .commentAppeared(let comment):
            guard comment.commentId == state.comments.last?.commentId, state.commentLastId != nil
            else {
                return .none
            }
            return fetch(&state, tab: .comments, reset: false)

        case .postsLoaded(let page):
            state.posts += page.items
            state.postLastId = page.lastId
            state.totalCount = page.count ?? state.posts.count
            state.isLoading = false
            return .none

        case .commentsLoaded(let page):
            state.comments += page.items
            state.commentLastId = page.lastId
            state.totalCount = page.count ?? state.comments.count
            state.isLoading = false
            return .none

        case .loadFailed:
            state.isLoading = false
            return .none

        case .postTapped(let post):
            return push(ExploreRoute.communityPost(id: post.postId))

        case .commentTapped(let comment):
            // 게시글 id가 없으면 아무것도 하지 않는다 (MC7)
            guard let postId = comment.postId else {
                return .none
            }
            return push(ExploreRoute.communityPost(id: postId))

        case .mainTabTapped(let tab):
            return .run { [openTab] in
                await openTab(tab)
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 레거시 `fetch(tab:reset:)`: 처음부터면 그 탭 목록·커서를 먼저 비운다. 받는 중이면 요청하지 않는다 (비운 것은 그대로)
    private func fetch(_ state: inout State, tab: Tab, reset: Bool) -> Effect<Intent> {
        if reset {
            switch tab {
            case .posts:
                state.posts.removeAll()
                state.postLastId = nil
            case .comments:
                state.comments.removeAll()
                state.commentLastId = nil
            }
        }
        guard !state.isLoading else {
            return .none
        }
        state.isLoading = true
        switch tab {
        case .posts:
            let lastId = state.postLastId
            return .run { [myInfoClient] in
                guard let page = try? await myInfoClient.myPosts(lastId: lastId) else {
                    return .loadFailed
                }
                return .postsLoaded(page)
            }
        case .comments:
            let lastId = state.commentLastId
            return .run { [myInfoClient] in
                guard let page = try? await myInfoClient.myComments(lastId: lastId) else {
                    return .loadFailed
                }
                return .commentsLoaded(page)
            }
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
