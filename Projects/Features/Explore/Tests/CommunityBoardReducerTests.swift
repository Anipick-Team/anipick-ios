import ClientCore
import CommunityClientInterface
import CommunityClientTesting
import ExploreInterface
import FeatureTestSupport
import MVICore
import Testing

@testable import ExploreFeature

/// 동작 목록 CP2~CP10 (notes/2026-10-30-R-explore-04-community-board.md)과 1:1
@Suite("커뮤니티 게시판", .timeLimit(.minutes(1)))
struct CommunityBoardReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: [Int], lastId: Int?, lastValue: String? = nil, spoilers: Set<Int> = [])
        -> Result<CommunityPostPage, TransportError>
    {
        return .success(
            CommunityPostPage(
                posts: ids.map { .sample($0, isSpoiler: spoilers.contains($0)) }, lastId: lastId,
                lastValue: lastValue))
    }

    private func makeStore(_ client: MockCommunityClient) -> Store<CommunityBoardReducer> {
        return Store(
            initialState: CommunityBoardReducer.State(
                seriesId: 7, animeTitle: "애니", coverImageUrl: nil, genreNames: ["액션"]),
            reducer: CommunityBoardReducer(communityClient: client, navigator: navigator))
    }

    private func request(_ sort: String = "latest", lastValue: String? = nil, lastId: Int? = nil)
        -> MockCommunityClient.PostsRequest
    {
        return .init(seriesId: 7, sort: sort, lastValue: lastValue, lastId: lastId)
    }

    @Test("CP2. 보일 때마다 커서 없이 처음부터 받아 바꾼다")
    func appears() async {
        let client = MockCommunityClient()
        client.stubPosts([page([1, 2], lastId: 2, lastValue: "x"), page([3], lastId: 3)])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(store.state.posts.map(\.id) == [1, 2])
        #expect(store.state.lastValue == "x")
        await store.send(.appeared).finish()

        #expect(store.state.posts.map(\.id) == [3])
        #expect(client.postsRequests == [request(), request()])
    }

    @Test("CP3. 받는 중에는 다시 보이거나 필터를 바꿔도 요청하지 않는다 (필터 표시는 바뀐다)")
    func ignoresWhileLoading() async {
        let client = MockCommunityClient(delay: .milliseconds(50))
        let store = makeStore(client)

        let first = store.send(.appeared)
        await store.send(.appeared).finish()
        await store.send(.filterSelected(.weekly)).finish()
        await first.finish()

        #expect(client.postsRequests == [request()])
        #expect(store.state.filter == .weekly)
    }

    @Test(
        "CP4. 필터를 바꾸면 그 정렬로 처음부터. 같은 필터는 받지 않는다",
        arguments: [
            (CommunityBoardReducer.Filter.monthly, "popularMonthly"), (.weekly, "popularWeekly"),
            (.daily, "popularDaily"),
        ])
    func filters(filter: CommunityBoardReducer.Filter, sort: String) async {
        let client = MockCommunityClient()
        client.stubPosts([page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.filterSelected(filter)).finish()
        await store.send(.filterSelected(filter)).finish()
        await store.send(.filterSelected(.all)).finish()

        #expect(client.postsRequests == [request(), request(sort), request()])
    }

    @Test("CP5. 마지막 글이 보이면 커서로 이어 받는다. 빈 페이지나 커서가 없으면 더 받지 않는다")
    func loadsMore() async {
        let client = MockCommunityClient()
        client.stubPosts([page([1, 2], lastId: 2, lastValue: "v"), page([3], lastId: nil)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.postAppeared(.sample(1))).finish()
        await store.send(.postAppeared(.sample(2))).finish()
        await store.send(.postAppeared(.sample(3))).finish()

        #expect(store.state.posts.map(\.id) == [1, 2, 3])
        #expect(!store.state.hasNextPage)
        #expect(client.postsRequests == [request(), request(lastValue: "v", lastId: 2)])
    }

    @Test("CP6. 스포일러를 끄면 스포일러 글을 화면에서만 뺀다. 마지막 글이 숨겨지면 이어 받지 못한다")
    func spoilers() async {
        let client = MockCommunityClient()
        client.stubPosts([page([1, 2], lastId: 2, spoilers: [2])])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.spoilerToggled).finish()

        #expect(store.state.visiblePosts.map(\.id) == [1])
        #expect(store.state.posts.map(\.id) == [1, 2])
    }

    @Test("CP7. 실패하면 안내를 띄우고, 다시 시도하면 처음부터 받는다 (요청할 때 안내를 지운다)")
    func failure() async {
        let client = MockCommunityClient()
        client.stubPosts([.failure(.offline), page([1], lastId: 1)])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(store.state.errorMessage == "게시글을 불러오지 못했습니다.")
        #expect(!store.state.isLoading)

        let retry = store.send(.retryTapped)
        #expect(store.state.errorMessage == nil)
        await retry.finish()

        #expect(store.state.posts.map(\.id) == [1])
    }

    @Test("CP8·CP9. 글은 게시글 상세로, 글쓰기 버튼은 이 게시판 글쓰기로, 뒤로는 pop")
    func navigation() async {
        let store = makeStore(MockCommunityClient())

        await store.send(.postTapped(.sample(4))).finish()
        await store.send(.writeTapped).finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(ExploreRoute.communityPost(id: 4)),
                    .push(ExploreRoute.communityWrite(seriesId: 7, animeTitle: "애니")), .pop,
                ])
    }
}
