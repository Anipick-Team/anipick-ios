import ClientCore
import DetailInterface
import ExploreClientInterface
import ExploreClientTesting
import ExploreInterface
import FeatureTestSupport
import HomeInterface
import MVICore
import MetadataClientInterface
import MetadataClientTesting
import Testing
import os

@testable import ExploreFeature

/// 동작 목록 EX1~EX16 (notes/2026-10-30-R-explore-02-main.md)과 1:1
@Suite("탐색 탭", .timeLimit(.minutes(1)))
struct ExploreReducerTests {
    private let navigator = RecordingNavigator()
    private let pending = OSAllocatedUnfairLock<PendingExploreFilter?>(initialState: nil)
    private let metadata = MockMetadataClient(
        genres: [Genre(id: 3, name: "SF"), Genre(id: 4, name: "액션")], seasonYears: [2026, 2025])

    private func page(_ ids: [Int], lastId: Int?) -> Result<ExplorePage?, TransportError> {
        return .success(ExplorePage(animes: ids.map { .sample($0) }, lastId: lastId))
    }

    private func makeStore(_ client: MockExploreClient, genres: [String] = ["SF", "액션"])
        -> Store<ExploreReducer>
    {
        return Store(
            initialState: ExploreReducer.State(
                genres: genres, years: ["2026", "2025"], types: ["TV"]),
            reducer: ExploreReducer(
                exploreClient: client, metadataClient: metadata, navigator: navigator,
                consumePendingFilter: { [pending] in
                    pending.withLock {
                        defer { $0 = nil }
                        return $0
                    }
                },
                sheetDelay: .milliseconds(10))
        )
    }

    private func query(
        sort: String = "popularity", year: Int? = nil, season: Int? = nil, genreIds: [Int]? = nil,
        type: String? = nil, lastId: Int? = nil, genreOp: String = "OR"
    ) -> ExploreQuery {
        return ExploreQuery(
            sort: sort, year: year, season: season, genreIds: genreIds, type: type, lastId: lastId,
            genreOp: genreOp)
    }

    @Test("EX1. 보이면 지금 커서로 이어 받는다 (넘겨받은 조건이 없을 때). 다시 보이면 다음 커서로")
    func appearsWithoutFilter() async {
        let client = MockExploreClient(explorePages: [
            page([1, 2], lastId: 2), page([2, 3], lastId: 3),
        ])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(client.exploreQueries == [query(), query(lastId: 2)])
        #expect(store.state.items.map(\.animeId) == [1, 2, 3])
    }

    @Test("EX1·EX2. 넘겨받은 연도·분기가 있으면 칩으로 넣고 처음부터 받는다. 보이는 중에 바뀌어도 받는다")
    func pendingFilter() async {
        let client = MockExploreClient(explorePages: [page([5], lastId: 5)])
        let store = makeStore(client)
        pending.withLock { $0 = PendingExploreFilter(year: "2025", season: "3") }

        await store.send(.appeared).finish()
        pending.withLock { $0 = PendingExploreFilter(year: nil, season: "4") }
        await store.send(.pendingFilterChanged).finish()

        #expect(
            store.state.tags
                == [
                    .init(category: .season, value: "4"), .init(category: .season, value: "3"),
                    .init(category: .yearQuarter, value: "2025"),
                ])
        // 분기 칩이 둘이 되고, 맨 앞(나중에 넣은 것)을 보낸다 (레거시 그대로)
        #expect(
            client.exploreQueries == [query(year: 2025, season: 3), query(year: 2025, season: 4)])
    }

    @Test("EX1. 메타데이터가 비었으면 다시 받는다")
    func refreshesMetadata() async {
        let store = makeStore(MockExploreClient(), genres: [])

        await store.send(.appeared).finish()

        #expect(store.state.genres == ["SF", "액션"])
        #expect(store.state.types == ["TV", "OVA", "MOVIE"])
    }

    @Test("EX3. 칩: 탭이 바뀌면 바로, 같은 탭이면 잠시 뒤 시트를 연다")
    func chips() async {
        let store = makeStore(MockExploreClient())

        let effect = store.send(.filterChipTapped(.genre))
        #expect(store.state.isFilterSheetPresented)
        #expect(store.state.filterTab == .genre)
        await effect.finish()
        await store.send(.filterSheetPresentedChanged(false)).finish()

        let same = store.send(.filterChipTapped(.genre))
        #expect(!store.state.isFilterSheetPresented)
        await same.finish()
        #expect(store.state.isFilterSheetPresented)
    }

    @Test("EX4·EX5·EX9. 년도/분기: 시트가 열리면 첫 연도·'전체'. 완료하면 같은 종류 칩을 바꾸고 처음부터 받는다 ('전체'는 보내지 않음)")
    func yearQuarter() async {
        let client = MockExploreClient(explorePages: [page([1], lastId: 1)])
        let store = makeStore(client)

        await store.send(.filterSheetAppeared).finish()
        #expect(store.state.pickerYear == "2026")
        #expect(store.state.pickerSeason == "전체")
        await store.send(.filterDoneTapped).finish()
        await store.send(.filterTabSelected(.yearQuarter)).finish()
        await store.send(.pickerYearChanged("2025")).finish()
        await store.send(.pickerSeasonChanged("2")).finish()
        await store.send(.filterDoneTapped).finish()

        #expect(
            store.state.tags
                == [
                    .init(category: .season, value: "2"),
                    .init(category: .yearQuarter, value: "2025"),
                ])
        #expect(client.exploreQueries == [query(year: 2026), query(year: 2025, season: 2)])
        #expect(store.state.tags.first?.title == "2분기")
    }

    @Test("EX6·EX9. 장르: 여러 개 고르고(다시 누르면 해제) 모든 조건 일치면 AND, 이름으로 id를 찾아 보낸다")
    func genres() async {
        let client = MockExploreClient(explorePages: [page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.filterTabSelected(.genre)).finish()

        await store.send(.genreToggled("SF")).finish()
        await store.send(.genreToggled("액션")).finish()
        await store.send(.genreToggled("SF")).finish()
        await store.send(.genreToggled("SF")).finish()
        await store.send(.matchAllGenresTapped).finish()
        await store.send(.filterDoneTapped).finish()

        #expect(store.state.pickedGenres.isEmpty)
        #expect(store.state.highlightedGenres == ["액션", "SF"])
        #expect(client.exploreQueries == [query(genreIds: [3, 4], genreOp: "AND")])
    }

    @Test("EX7·EX8. 타입은 하나만. 초기화는 칩·커서·시트 선택을 비우고 다시 받지 않는다")
    func typeAndReset() async {
        let client = MockExploreClient(explorePages: [page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.filterTabSelected(.type)).finish()
        await store.send(.typeSelected("TV")).finish()
        await store.send(.filterDoneTapped).finish()
        #expect(client.exploreQueries == [query(type: "TV")])

        await store.send(.filterResetTapped).finish()

        #expect(store.state.tags.isEmpty)
        #expect(store.state.lastId == nil)
        #expect(store.state.pickerType == "")
        #expect(client.exploreQueries.count == 1)
    }

    @Test("EX10. 칩을 지우면 다시 처음부터. 연도를 지우면 분기도 함께 지운다")
    func removeTags() async {
        let client = MockExploreClient(explorePages: [page([1], lastId: 1)])
        let store = makeStore(client)
        pending.withLock { $0 = PendingExploreFilter(year: "2025", season: "3") }
        await store.send(.appeared).finish()

        await store.send(.tagRemoved(.init(category: .yearQuarter, value: "2025"))).finish()

        #expect(store.state.tags.isEmpty)
        #expect(client.exploreQueries.last == query())
    }

    @Test("EX11. 정렬: 고르면 메뉴를 닫고 목록·커서를 비운 뒤 그 정렬로 처음부터")
    func sort() async {
        let client = MockExploreClient(explorePages: [page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.sortButtonTapped).finish()

        await store.send(.sortSelected(.rating)).finish()

        #expect(!store.state.isSortMenuPresented)
        #expect(client.exploreQueries == [query(sort: "rating")])
    }

    @Test("EX12·EX13. 마지막 칸이 보이면 이어 받는다. 칸은 상세로, 검색은 홈 검색으로")
    func loadMoreAndNavigation() async {
        let client = MockExploreClient(explorePages: [page([1, 2], lastId: 2)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()
        await store.send(.itemTapped(.sample(2))).finish()
        await store.send(.searchTapped).finish()

        #expect(client.exploreQueries.count == 2)
        #expect(navigator.actions == [.push(DetailRoute.anime(id: 2)), .push(HomeRoute.search)])
    }

    @Test("EX14. 하위 탭 전환")
    func mainTab() async {
        let store = makeStore(MockExploreClient())

        await store.send(.mainTabSelected(.community)).finish()

        #expect(store.state.mainTab == .community)
    }
}
