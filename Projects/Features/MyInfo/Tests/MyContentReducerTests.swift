import ClientCore
import ExploreInterface
import FeatureTestSupport
import MVICore
import MyInfoClientInterface
import MyInfoClientTesting
import MyInfoInterface
import Testing

@testable import MyInfoFeature

/// 동작 목록 MC2~MC10 (notes/2026-10-29-R-myinfo-03-content.md)과 1:1. MC8(가짜 탭 바)은 Phase 4-2에서 지웠다
@Suite("내 콘텐츠", .timeLimit(.minutes(1)))
struct MyContentReducerTests {
    private let navigator = RecordingNavigator()

    private func makeStore(_ scenario: MockMyInfoClient.Scenario) -> (
        Store<MyContentReducer>, MockMyInfoClient
    ) {
        let client = MockMyInfoClient(scenario)
        let store = Store(
            initialState: MyContentReducer.State(),
            reducer: MyContentReducer(
                myInfoClient: client, navigator: navigator)
        )
        return (store, client)
    }

    private func posts(_ ids: [Int], count: Int?, lastId: Int?) -> Result<
        ContentPage<MyPost>, TransportError
    > {
        return .success(ContentPage(count: count, lastId: lastId, items: ids.map { .sample($0) }))
    }

    @Test("MC2. 보일 때마다 지금 탭을 처음부터 다시 받는다")
    func reloadsOnAppear() async {
        let (store, client) = makeStore(.init(postPage: posts([1, 2], count: 5, lastId: 2)))

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.posts.map(\.postId) == [1, 2])
        #expect(client.requests == [.myPosts(lastId: nil), .myPosts(lastId: nil)])
        #expect(store.state.totalCount == 5)
    }

    @Test("MC3. 탭을 바꾸면 그 탭을 처음부터 받는다. 같은 탭을 다시 누르면 받지 않는다. 총 개수는 두 탭이 함께 쓴다")
    func switchesTab() async {
        let (store, client) = makeStore(
            .init(
                postPage: posts([1], count: 9, lastId: 1),
                commentPage: .success(ContentPage(count: 3, lastId: 7, items: [.sample(7)]))))
        await store.send(.appeared).finish()

        await store.send(.tabSelected(.comments)).finish()
        await store.send(.tabSelected(.comments)).finish()

        #expect(store.state.tab == .comments)
        #expect(store.state.comments.map(\.commentId) == [7])
        #expect(store.state.totalCount == 3)
        #expect(client.requests == [.myPosts(lastId: nil), .myComments(lastId: nil)])
    }

    @Test("MC4. 총 개수가 없으면 받은 개수, 999를 넘으면 999+")
    func totalCount() async {
        let (store, _) = makeStore(.init(postPage: posts([1, 2, 3], count: nil, lastId: nil)))

        await store.send(.appeared).finish()

        #expect(store.state.totalCount == 3)
        var state = MyContentReducer.State()
        state.totalCount = 1000
        #expect(state.totalCountText == "999+")
        state.totalCount = 999
        #expect(state.totalCountText == "999")
    }

    @Test("MC5. 마지막 칸이 보이고 커서가 있으면 이어 받는다. 커서가 없으면 받지 않는다")
    func loadsMore() async {
        let (store, client) = makeStore(.init(postPage: posts([1, 2], count: 4, lastId: 2)))
        await store.send(.appeared).finish()

        await store.send(.postAppeared(.sample(1))).finish()
        await store.send(.postAppeared(.sample(2))).finish()

        #expect(client.requests == [.myPosts(lastId: nil), .myPosts(lastId: 2)])
        #expect(store.state.posts.map(\.postId) == [1, 2, 1, 2])

        let (noCursor, noCursorClient) = makeStore(
            .init(postPage: posts([1], count: 1, lastId: nil)))
        await noCursor.send(.appeared).finish()
        await noCursor.send(.postAppeared(.sample(1))).finish()
        #expect(noCursorClient.requests.count == 1)
    }

    @Test("MC3. 받는 중에 탭을 바꾸면 그 탭 목록은 비우지만 요청하지 않는다 (레거시 그대로)")
    func switchWhileLoading() async {
        let (store, client) = makeStore(
            .init(postPage: posts([1], count: 1, lastId: nil), contentDelay: .milliseconds(200)))
        let first = store.send(.appeared)
        #expect(await waitUntil { client.requests.count == 1 })

        await store.send(.tabSelected(.comments)).finish()

        #expect(client.requests == [.myPosts(lastId: nil)])
        await first.finish()
        #expect(store.state.isLoading == false)
    }

    @Test("MC9. 실패하면 받는 중 표시만 끈다")
    func failure() async {
        let (store, _) = makeStore(.init(postPage: .failure(.offline)))

        await store.send(.appeared).finish()

        #expect(store.state.isLoading == false)
        #expect(store.state.posts.isEmpty)
    }

    @Test("MC7. 게시글·댓글을 누르면 커뮤니티 게시글로. 댓글의 게시글 id가 없으면 이동하지 않는다. 뒤로는 pop")
    func navigation() async {
        let (store, _) = makeStore(.init())

        await store.send(.postTapped(.sample(4))).finish()
        await store.send(.commentTapped(.sample(5, postId: 40))).finish()
        await store.send(.commentTapped(.sample(6, postId: nil))).finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(ExploreRoute.communityPost(id: 4)),
                    .push(ExploreRoute.communityPost(id: 40)), .pop,
                ])
    }
}
