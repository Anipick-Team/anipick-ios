import DetailInterface
import FeatureTestSupport
import MVICore
import MyInfoClientInterface
import MyInfoClientTesting
import Testing

@testable import MyInfoFeature

/// 동작 목록 W·LA·LP (notes/2026-10-29-R-myinfo-01-lists.md)과 1:1
@Suite("마이페이지 목록", .timeLimit(.minutes(1)))
struct MyInfoListReducerTests {
    private let navigator = RecordingNavigator()

    private func animePage(_ ids: [Int], count: Int, lastId: Int?) -> MockMyInfoClient.Scenario {
        return .init(
            animePage: .success(
                MyPage(count: count, items: ids.map { .sample($0) }, lastId: lastId)))
    }

    @Test("W1. 상태별 제목과 빈 화면 문구", arguments: WatchStatus.allCases)
    func titles(status: WatchStatus) {
        let state = WatchListReducer.State(status: status)
        let expected: [WatchStatus: (String, String)] = [
            .watchList: ("볼 애니", "아직 볼 애니가 없어요!"),
            .watching: ("보는 중", "아직 보는 중인 작품이 없어요!"),
            .finished: ("다 본 애니", "아직 다 본 작품이 없어요!"),
        ]

        #expect(state.title == expected[status]?.0)
        #expect(state.emptyMessage == expected[status]?.1)
    }

    @Test("W3. 보일 때마다 지금 커서로 받아 이어 붙인다 (상세에서 돌아와도)", arguments: WatchStatus.allCases)
    func fetchesOnEveryAppear(status: WatchStatus) async {
        let client = MockMyInfoClient(animePage([1, 2], count: 12, lastId: 2))
        let store = Store(
            initialState: WatchListReducer.State(status: status),
            reducer: WatchListReducer(status: status, myInfoClient: client, navigator: navigator)
        )

        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 2 })
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 4 })

        #expect(
            client.requests == [.watchList(status, lastId: nil), .watchList(status, lastId: 2)])
        #expect(store.state.count == 12)
    }

    @Test("W4. 마지막 칸이 보이면 다음 페이지, 아니면 받지 않는다")
    func loadsMoreAtLastItem() async {
        let client = MockMyInfoClient(animePage([1, 2], count: 4, lastId: 2))
        let store = Store(
            initialState: WatchListReducer.State(status: .watching),
            reducer: WatchListReducer(status: .watching, myInfoClient: client, navigator: navigator)
        )
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 2 })

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()

        #expect(await waitUntil { client.requests.count == 2 })
        #expect(client.requests.last == .watchList(.watching, lastId: 2))
    }

    @Test("W8. 실패하면 아무것도 바꾸지 않는다")
    func failureChangesNothing() async {
        let client = MockMyInfoClient(.init(animePage: .failure(.offline)))
        let store = Store(
            initialState: WatchListReducer.State(status: .finished),
            reducer: WatchListReducer(status: .finished, myInfoClient: client, navigator: navigator)
        )

        await store.send(.appeared).finish()

        #expect(store.state == WatchListReducer.State(status: .finished))
    }

    @Test("W5·W7·LA3·LP3. 칸을 누르면 상세(인물은 성우 상세)로, 뒤로는 pop. id가 없으면 0")
    func navigation() async {
        let client = MockMyInfoClient()
        let watch = Store(
            initialState: WatchListReducer.State(status: .watchList),
            reducer: WatchListReducer(
                status: .watchList, myInfoClient: client, navigator: navigator)
        )
        let animes = Store(
            initialState: LikedAnimesReducer.State(),
            reducer: LikedAnimesReducer(myInfoClient: client, navigator: navigator)
        )
        let persons = Store(
            initialState: LikedPersonsReducer.State(),
            reducer: LikedPersonsReducer(myInfoClient: client, navigator: navigator)
        )

        await watch.send(.itemTapped(.sample(3))).finish()
        await watch.send(.itemTapped(MyAnime(animeId: nil, title: nil, coverImageUrl: nil)))
            .finish()
        await animes.send(.itemTapped(.sample(4))).finish()
        await persons.send(.itemTapped(.sample(5))).finish()
        await watch.send(.backTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(DetailRoute.anime(id: 3)), .push(DetailRoute.anime(id: 0)),
                    .push(DetailRoute.anime(id: 4)), .push(DetailRoute.voiceActor(id: 5)), .pop,
                ])
    }

    @Test("LA1·LA2. 좋아요한 작품: 처음 한 번만 받고, 이어 붙이지 않고 바꾼다")
    func likedAnimes() async {
        let client = MockMyInfoClient(animePage([7, 8, 9], count: 30, lastId: 9))
        let store = Store(
            initialState: LikedAnimesReducer.State(),
            reducer: LikedAnimesReducer(myInfoClient: client, navigator: navigator)
        )

        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 3 })
        await store.send(.appeared).finish()

        #expect(client.requests == [.likedAnimes(lastId: nil)])
        #expect(store.state.count == 30)
        #expect(store.state.lastId == 9)
    }

    @Test("LP1·LP2. 좋아요한 인물: 처음 한 번 받고, 마지막 사람이 보이면 커서로 이어 받는다")
    func likedPersons() async {
        let client = MockMyInfoClient(
            .init(
                personPage: .success(MyPage(count: 31, items: [.sample(1), .sample(2)], lastId: 2)))
        )
        let store = Store(
            initialState: LikedPersonsReducer.State(),
            reducer: LikedPersonsReducer(myInfoClient: client, navigator: navigator)
        )
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 2 })
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()

        #expect(await waitUntil { store.state.items.count == 4 })
        #expect(client.requests == [.likedPersons(lastId: nil), .likedPersons(lastId: 2)])
        #expect(store.state.count == 31)
    }
}
