import ClientCore
import CommunityClientInterface
import CommunityClientTesting
import ExploreInterface
import FeatureTestSupport
import MVICore
import Testing

@testable import ExploreFeature

/// 동작 목록 CB1~CB10 (notes/2026-10-30-R-explore-01-community-boards.md)과 1:1
@Suite("탐색 커뮤니티", .timeLimit(.minutes(1)))
struct CommunityBoardsReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: [Int], lastId: Int?, lastValue: String? = nil)
        -> Result<CommunityBoardPage, TransportError>
    {
        return .success(
            CommunityBoardPage(
                boards: ids.map { .sample($0) }, lastId: lastId, lastValue: lastValue))
    }

    private func makeStore(_ client: MockCommunityClient) -> Store<CommunityBoardsReducer> {
        return Store(
            initialState: CommunityBoardsReducer.State(),
            reducer: CommunityBoardsReducer(
                communityClient: client, navigator: navigator, searchDelay: .milliseconds(10)))
    }

    private func request(
        _ sort: String = "popular", keyword: String? = nil, lastValue: String? = nil,
        lastId: Int? = nil
    )
        -> MockCommunityClient.BoardsRequest
    {
        return .init(sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId)
    }

    @Test("CB2. 보이면 인기순 첫 페이지를 받는다. 제목이 없으면 '제목 없음', 장르가 없으면 '커뮤니티'")
    func firstPage() async {
        let client = MockCommunityClient(boards: [
            .success(
                CommunityBoardPage(
                    boards: [
                        CommunityBoard(seriesId: 1, title: nil, coverImageUrl: nil, genres: [])
                    ],
                    lastId: 1, lastValue: "v"))
        ])
        let store = makeStore(client)

        await store.send(.appeared).finish()

        #expect(client.boardRequests == [request()])
        #expect(store.state.items.first?.title == "제목 없음")
        #expect(store.state.items.first?.tag == "커뮤니티")
        #expect(store.state.isLoading == false)
    }

    @Test("CB3. 검색어를 바꾸면 앞뒤 공백을 뺀 검색어로 잠시 뒤 처음부터 받는다. 지우기는 검색어를 비운다")
    func search() async {
        let client = MockCommunityClient(boards: [page([1], lastId: 1)])
        let store = makeStore(client)

        await store.send(.searchTextChanged(" 나루토 ")).finish()
        await store.send(.clearSearchTapped).finish()

        #expect(store.state.searchText == "")
        #expect(client.boardRequests == [request(keyword: "나루토"), request()])
    }

    @Test("CB4·CB5. 마지막 칸이 보이면 커서로 이어 붙인다. 빈 페이지나 커서가 없으면 더 받지 않는다")
    func loadsMore() async {
        let client = MockCommunityClient(boards: [
            page([1, 2], lastId: 2, lastValue: "x"), page([], lastId: nil),
        ])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(store.state.items[1])).finish()
        await store.send(.itemAppeared(store.state.items[1])).finish()

        #expect(client.boardRequests == [request(), request(lastValue: "x", lastId: 2)])
        #expect(store.state.hasNextPage == false)
        #expect(store.state.items.count == 2)
    }

    @Test("CB6. 받는 중에는 다시 요청하지 않는다")
    func guardsWhileLoading() async {
        let client = MockCommunityClient(boards: [page([1], lastId: 1)], delay: .milliseconds(200))
        let store = makeStore(client)

        let first = store.send(.appeared)
        await store.send(.retryTapped).finish()

        #expect(store.state.isLoading)
        await first.finish()
        #expect(client.boardRequests.count == 1)
    }

    @Test("CB7. 실패하면 안내 문구, 다시 시도는 처음부터 받는다")
    func failure() async {
        let client = MockCommunityClient(boards: [.failure(.offline), page([1], lastId: nil)])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(store.state.errorMessage == "커뮤니티 게시판을 불러오지 못했습니다.")
        await store.send(.retryTapped).finish()

        #expect(store.state.errorMessage == nil)
        #expect(store.state.items.count == 1)
    }

    @Test("CB8. 정렬: 메뉴를 열고, 최신순을 고르면 닫고 latest로 처음부터. 바깥을 누르면 닫힌다")
    func sort() async {
        let client = MockCommunityClient(boards: [page([1], lastId: 1)])
        let store = makeStore(client)

        await store.send(.sortButtonTapped).finish()
        #expect(store.state.isSortMenuPresented)
        await store.send(.sortSelected("최신순")).finish()
        #expect(!store.state.isSortMenuPresented)
        #expect(store.state.sortTitle == "최신순")
        await store.send(.sortButtonTapped).finish()
        await store.send(.backgroundTapped).finish()

        #expect(!store.state.isSortMenuPresented)
        #expect(client.boardRequests == [request("latest")])
    }

    @Test("CB9. 칸을 누르면 그 애니 커뮤니티 게시판으로 (제목·표지·장르 이름 전달)")
    func navigation() async {
        let client = MockCommunityClient(boards: [page([7], lastId: nil)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.itemTapped(store.state.items[0])).finish()

        #expect(
            navigator.actions
                == [
                    .push(
                        ExploreRoute.communityBoard(
                            seriesId: 7, animeTitle: "애니 7", coverImageUrl: nil,
                            genreNames: ["액션", "판타지"]))
                ])
    }
}
