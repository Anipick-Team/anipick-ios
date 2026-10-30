import Analytics
import ClientCore
import DetailInterface
import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import MVICore
import Testing

@testable import HomeFeature

/// 동작 목록 HS4~HS15 (notes/2026-10-30-R-home-04-search.md)과 1:1
@Suite("홈 검색", .timeLimit(.minutes(1)))
struct HomeSearchReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()

    private func makeStore(_ client: MockHomeClient) -> Store<HomeSearchReducer> {
        return Store(
            initialState: .init(),
            reducer: HomeSearchReducer(homeClient: client, navigator: navigator, analytics: tracker)
        )
    }

    private func animes(_ ids: [Int], count: Int = 10, lastId: Int?) -> Result<
        SearchPage<SearchAnime>?, TransportError
    > {
        return .success(SearchPage(items: ids.map { .sample($0) }, count: count, lastId: lastId))
    }

    @Test("HS4. 보일 때마다 최근 검색어를 읽고(없으면 숨김) 인기 작품을 받는다")
    func appears() async {
        let client = MockHomeClient()
        client.stubSearch(popular: .success([.sample(1)]), keywords: ["a", "b"])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(store.state.recentKeywords == ["a", "b"])
        #expect(store.state.isRecentKeywordsShown)
        #expect(store.state.popularAnimes.map(\.animeId) == [1])

        client.setRecentKeywords([])
        await store.send(.appeared).finish()
        #expect(!store.state.isRecentKeywordsShown)
        #expect(client.requests == [.popular, .popular])
    }

    @Test("HS5. 검색: 목록을 비우고 검색어를 저장한 뒤 작품 → 인물 → 제작사 차례로 받는다. 화면 목록에는 중복도 앞에 넣는다")
    func submit() async {
        let client = MockHomeClient()
        client.stubSearch(
            animes: [animes([1], count: 7, lastId: 1)],
            persons: [.success(SearchPage(items: [.sample(2)], count: 3, lastId: 2))],
            studios: [.success(SearchPage(items: [.sample(3)], count: 1, lastId: nil))],
            keywords: ["원피스"])
        let store = makeStore(client)
        await store.send(.appeared).finish()
        await store.send(.searchTextChanged("원피스")).finish()

        await store.send(.submitted).finish()
        #expect(await waitUntil { store.state.studios.count == 1 })

        #expect(store.state.selectedTab == .animation)
        #expect(store.state.recentKeywords == ["원피스", "원피스"])
        #expect(client.storedKeywords == ["원피스"])
        #expect(
            client.requests.filter { $0 != .popular }
                == [
                    .searchAnimes(query: "원피스", lastId: nil),
                    .searchPersons(query: "원피스", lastId: nil),
                    .searchStudios(query: "원피스", lastId: nil),
                ])
        #expect(
            [store.state.animeCount, store.state.personCount, store.state.studioCount] == [7, 3, 1])
    }

    @Test("HS6. 빈 검색어로 보내면 목록만 비운다. 검색어를 지우면 인기 작품 화면으로")
    func emptySubmitAndClear() async {
        let client = MockHomeClient()
        let store = makeStore(client)
        await store.send(.tabSelected(.person)).finish()

        await store.send(.submitted).finish()
        #expect(client.requests.isEmpty)
        await store.send(.searchTextChanged("a")).finish()
        #expect(store.state.selectedTab == .person)
        await store.send(.clearTapped).finish()

        #expect(store.state.searchText == "")
        #expect(store.state.selectedTab == .initSearch)
    }

    @Test("HS7. 다시 검색해도 커서는 그대로 쓴다 (레거시 그대로) — 두 번째 검색이 이전 커서로 간다")
    func keepsCursorAcrossSearches() async {
        let client = MockHomeClient()
        client.stubSearch(animes: [animes([1], lastId: 5)])
        let store = makeStore(client)
        await store.send(.searchTextChanged("a")).finish()
        await store.send(.submitted).finish()
        #expect(
            await waitUntil { client.requests.contains(.searchStudios(query: "a", lastId: nil)) })

        await store.send(.searchTextChanged("b")).finish()
        await store.send(.submitted).finish()

        #expect(await waitUntil { client.requests.contains(.searchAnimes(query: "b", lastId: 5)) })
    }

    @Test("HS8. 작품 결과의 마지막 페이지(커서 없음)면 검색 이벤트를 남기고, 노출·클릭 로그 주소를 보낸다")
    func analyticsAndLogs() async {
        let client = MockHomeClient()
        client.stubSearch(
            animes: [
                .success(
                    SearchPage(
                        items: [
                            .sample(1, clickLog: "https://c/1", impressionLog: "https://i/1"),
                            .sample(2),
                        ], count: 2,
                        lastId: nil))
            ])
        let store = makeStore(client)
        await store.send(.searchTextChanged("나루토")).finish()

        await store.send(.submitted).finish()

        #expect(await waitUntil { tracker.events.contains(.search(query: "나루토")) })
        #expect(await waitUntil { client.requests.contains(.trackingLog("https://i/1")) })
        #expect(client.requests.contains(.trackingLog("https://c/1")))
    }

    @Test("HS9. 작품 검색이 실패하면 오류를 남기고 인물·제작사는 계속 받는다. 결과가 없으면 인기 작품을 비운다")
    func animeFailure() async {
        let client = MockHomeClient()
        client.stubSearch(
            popular: .success([.sample(1)]), animes: [.failure(.offline), .success(nil)])
        let store = makeStore(client)
        await store.send(.appeared).finish()
        await store.send(.searchTextChanged("a")).finish()

        await store.send(.submitted).finish()
        #expect(
            await waitUntil { client.requests.contains(.searchStudios(query: "a", lastId: nil)) })
        #expect(await waitUntil { tracker.nonFatals.count == 1 })
        #expect(tracker.nonFatals.first?.breadcrumb.hasPrefix("[fetchAnimeSearchList]") == true)

        await store.send(.submitted).finish()
        #expect(await waitUntil { store.state.popularAnimes.isEmpty })
    }

    @Test("HS10. 최근 검색어를 누르면 그 검색어로 찾는다 (저장은 하지 않는다)")
    func keywordTap() async {
        let client = MockHomeClient()
        client.stubSearch(keywords: ["a"])
        let store = makeStore(client)

        await store.send(.keywordTapped("a")).finish()

        #expect(store.state.searchText == "a")
        #expect(store.state.selectedTab == .animation)
        #expect(store.state.isRecentKeywordsShown)
        #expect(client.requests.first == .searchAnimes(query: "a", lastId: nil))
        #expect(client.storedKeywords == ["a"])
    }

    @Test("HS11. 검색어 X는 화면·저장소에서 빼고, 다 빠지면 숨긴다. 전체삭제는 모두 지운다")
    func removeKeywords() async {
        let client = MockHomeClient()
        client.stubSearch(keywords: ["a", "b"])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.keywordRemoved("a")).finish()
        #expect(client.storedKeywords == ["b"])
        #expect(store.state.isRecentKeywordsShown)
        await store.send(.keywordRemoved("b")).finish()
        #expect(!store.state.isRecentKeywordsShown)

        client.setRecentKeywords(["c"])
        await store.send(.appeared).finish()
        await store.send(.clearAllKeywordsTapped).finish()
        #expect(client.storedKeywords.isEmpty)
        #expect(store.state.recentKeywords.isEmpty)
    }

    @Test("HS12. 각 탭의 마지막 칸이 보이면 그 탭만 이어 받는다 (커서가 없어도 받는다)")
    func loadsMore() async {
        let client = MockHomeClient()
        client.stubSearch(
            animes: [animes([1, 2], lastId: 2), animes([3], lastId: nil)],
            persons: [.success(SearchPage(items: [.sample(5)], count: 1, lastId: nil))],
            studios: [.success(SearchPage(items: [.sample(6)], count: 1, lastId: nil))])
        let store = makeStore(client)
        await store.send(.searchTextChanged("q")).finish()
        await store.send(.submitted).finish()
        #expect(await waitUntil { store.state.studios.count == 1 })

        await store.send(.animeAppeared(.sample(1))).finish()
        await store.send(.animeAppeared(.sample(2))).finish()
        await store.send(.personAppeared(.sample(5))).finish()
        await store.send(.studioAppeared(.sample(6))).finish()

        #expect(store.state.animes.map(\.animeId) == [1, 2, 3])
        #expect(
            Array(client.requests.suffix(3))
                == [
                    .searchAnimes(query: "q", lastId: 2), .searchPersons(query: "q", lastId: nil),
                    .searchStudios(query: "q", lastId: nil),
                ])
        #expect(store.state.persons.count == 2)
    }

    @Test("HS13·HS14. 작품은 상세, 인물은 성우 상세, 제작사는 제작사 상세로 (id가 없으면 0). 뒤로는 pop")
    func navigation() async {
        let store = makeStore(MockHomeClient())

        await store.send(.animeTapped(animeId: 3)).finish()
        await store.send(.animeTapped(animeId: nil)).finish()
        await store.send(.personTapped(.sample(4))).finish()
        await store.send(.studioTapped(.sample(5))).finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(DetailRoute.anime(id: 3)), .push(DetailRoute.anime(id: 0)),
                    .push(DetailRoute.voiceActor(id: 4)),
                    .push(DetailRoute.producer(id: 5)), .pop,
                ])
    }
}
