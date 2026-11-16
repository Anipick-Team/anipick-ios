import ClientCore
import DetailInterface
import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import MVICore
import Testing

@testable import HomeFeature

/// 동작 목록 CS2~CS7 (notes/2026-10-30-R-home-02-coming-soon-weekday.md)과 1:1
@Suite("공개 예정", .timeLimit(.minutes(1)))
struct ComingSoonReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockHomeClient()

    private func page(_ ids: [Int], lastId: Int?) -> Result<ComingSoonPage?, TransportError> {
        return .success(ComingSoonPage(animes: ids.map { .sample($0) }, lastId: lastId))
    }

    private func makeStore() -> Store<ComingSoonReducer> {
        return Store(
            initialState: .init(),
            reducer: ComingSoonReducer(homeClient: client, navigator: navigator))
    }

    @Test("CS2. 보일 때마다 커서 없이 첫 페이지를 받아 바꾼다 (19세 포함은 늘 false)")
    func appears() async {
        client.stubComingSoon([page([1, 2], lastId: 2), page([3], lastId: 3)])
        let store = makeStore()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [3])
        #expect(
            client.requests
                == [
                    .comingSoon(sort: "latest", lastId: nil, includeAdult: false),
                    .comingSoon(sort: "latest", lastId: nil, includeAdult: false),
                ])
    }

    @Test("CS3. 마지막 칸이 보이고 커서가 있으면 이어 받는다. 이미 있는 작품은 뺀다")
    func loadsMore() async {
        client.stubComingSoon([page([1, 2], lastId: 2), page([2, 3], lastId: nil)])
        let store = makeStore()
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()
        await store.send(.itemAppeared(.sample(3))).finish()

        #expect(store.state.items.map(\.animeId) == [1, 2, 3])
        #expect(client.requests.last == .comingSoon(sort: "latest", lastId: 2, includeAdult: false))
        #expect(client.requests.count == 2)
    }

    @Test("CS4. 정렬 버튼은 메뉴만 연다. 정렬을 고르면 메뉴를 닫고 목록을 비운 뒤 그 정렬로 첫 페이지")
    func sort() async {
        client.stubComingSoon([page([1], lastId: 1)])
        let store = makeStore()
        await store.send(.appeared).finish()
        await store.send(.sortButtonTapped).finish()
        #expect(store.state.isSortMenuPresented)
        #expect(client.requests.count == 1)

        let effect = store.send(.sortSelected(.startDate))
        #expect(store.state.items.isEmpty)
        #expect(!store.state.isSortMenuPresented)
        await effect.finish()

        #expect(
            client.requests.last == .comingSoon(sort: "startDate", lastId: nil, includeAdult: false)
        )
        #expect(ComingSoonReducer.Sort.allCases.map(\.title) == ["최신순", "인기순", "방영 예정 순"])
    }

    @Test("CS5. 실패하거나 목록이 없으면 아무것도 바꾸지 않는다")
    func failure() async {
        client.stubComingSoon([page([1], lastId: 1), .failure(.offline), .success(nil)])
        let store = makeStore()
        await store.send(.appeared).finish()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [1])
    }

    @Test("CS6·CS7. 칸은 상세로(id가 없으면 0), 뒤로는 pop")
    func navigation() async {
        let store = makeStore()

        await store.send(.itemTapped(.sample(5))).finish()
        await store.send(
            .itemTapped(
                ComingSoonAnime(animeId: nil, title: nil, coverImageUrl: nil, releaseDate: nil))
        )
        .finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions == [
                .push(DetailRoute.anime(id: 5)), .push(DetailRoute.anime(id: 0)), .pop,
            ])
    }
}
