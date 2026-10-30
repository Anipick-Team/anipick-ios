import ClientCore
import DetailInterface
import FeatureTestSupport
import HomeInterface
import MVICore
import MetadataClientTesting
import RankingClientInterface
import RankingClientTesting
import Testing

@testable import RankingFeature

/// 동작 목록 R1~R13 (notes/2026-10-29-R-ranking-01-ranking.md)과 1:1
@Suite("랭킹", .timeLimit(.minutes(1)))
struct RankingReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: ClosedRange<Int>, lastId: Int, lastValue: String? = nil) -> RankingPage
    {
        return RankingPage(
            animes: ids.map { RankedAnime.sample(id: $0, rank: $0) },
            lastId: lastId,
            lastValue: lastValue
        )
    }

    private func makeStore(_ client: MockRankingClient) -> Store<RankingReducer> {
        return Store(
            initialState: RankingReducer.State(genres: ["액션", "코미디"]),
            reducer: RankingReducer(
                rankingClient: client,
                metadataClient: MockMetadataClient(seasonYears: [2026, 2025]),
                navigator: navigator
            )
        )
    }

    @Test("R4·R5. 처음 보이면 실시간 첫 페이지를 받고 커서를 기억한다. 목록이 있으면 다시 받지 않는다")
    func loadsFirstPage() async {
        let client = MockRankingClient([.success(page(1...3, lastId: 30, lastValue: "8.1"))])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 3 })
        await store.send(.appeared).finish()

        #expect(client.requests == [.realTime(genre: nil, lastId: nil, lastValue: nil)])
        #expect(store.state.lastId == 30)
        #expect(store.state.lastValue == "8.1")
        #expect(store.state.isLoadingPage == false)
    }

    @Test("R8. 마지막 줄이 보이면 커서로 다음 페이지를 이어 붙인다. 마지막이 아니면 받지 않는다")
    func loadsMore() async {
        let client = MockRankingClient([
            .success(page(1...2, lastId: 20, lastValue: "9")),
            .success(page(3...4, lastId: 40, lastValue: "7")),
        ])
        let store = makeStore(client)
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.items.count == 2 })

        await store.send(.itemAppeared(store.state.items[0])).finish()
        await store.send(.itemAppeared(store.state.items[1])).finish()

        #expect(await waitUntil { store.state.items.count == 4 })
        #expect(
            client.requests
                == [
                    .realTime(genre: nil, lastId: nil, lastValue: nil),
                    .realTime(genre: nil, lastId: 20, lastValue: "9"),
                ])
    }

    @Test("R5. 실시간은 받는 중에 다시 요청하지 않는다")
    func realTimeGuardsWhileLoading() async {
        let client = MockRankingClient(
            [.success(page(1...1, lastId: 1))], delay: .milliseconds(300))
        let store = makeStore(client)

        // 첫 요청이 끝나기 전에 (finish를 기다리지 않고) 다시 요청한다
        let first = store.send(.appeared)
        #expect(await waitUntil { client.requests.count == 1 })
        await store.send(.genreResetTapped).finish()

        #expect(store.state.isLoadingPage)
        #expect(client.requests.count == 1)
        await first.finish()
    }

    @Test("R5·R6. 실패하면 목록을 그대로 두고 다시 받을 수 있게 한다")
    func failureKeepsList() async {
        let client = MockRankingClient([.failure(.offline)])
        let store = makeStore(client)

        await store.send(.appeared).finish()

        #expect(await waitUntil { store.state.isLoadingPage == false })
        #expect(store.state.items.isEmpty)
    }

    @Test("R3. 연도/분기를 누르면 시트를 열고, 비우기 전 연도·분기로 첫 페이지를 요청한 뒤 비운다")
    func yearSeasonFilter() async {
        let client = MockRankingClient([.success(page(1...2, lastId: 9))])
        let store = makeStore(client)
        await store.send(.filterTapped(.yearSeason)).finish()
        #expect(store.state.isYearSeasonSheetPresented)
        #expect(store.state.seasonYears == ["2026", "2025"])
        await store.send(.yearSeasonSheetAppeared).finish()
        await store.send(.pickerYearChanged("2025")).finish()
        await store.send(.pickerSeasonChanged("3")).finish()
        await store.send(.yearSeasonDoneTapped).finish()
        #expect(store.state.yearSeasonChipTitle == "2025/3분기")

        await store.send(.filterTapped(.yearSeason)).finish()

        #expect(
            client.requests
                == [
                    .yearSeason(year: 2025, season: nil, genre: nil, lastId: nil, lastRank: nil),
                    .yearSeason(year: 2025, season: 3, genre: nil, lastId: nil, lastRank: nil),
                    .yearSeason(year: 2025, season: 3, genre: nil, lastId: nil, lastRank: nil),
                ])
        #expect(store.state.selectedYear == "")
        #expect(store.state.yearSeasonChipTitle == "년도/분기")
    }

    @Test("R10. 연도/분기 시트: 처음 열면 첫 연도와 전체 분기, 전체 분기로 완료하면 분기 없이 요청하고 칩은 '2026/분기'")
    func yearSeasonSheetDefaults() async {
        let client = MockRankingClient([.success(page(1...1, lastId: 1))])
        let store = makeStore(client)
        await store.send(.filterTapped(.yearSeason)).finish()

        await store.send(.yearSeasonSheetAppeared).finish()
        #expect(store.state.pickerYear == "2026")
        #expect(store.state.pickerSeason == "전체 분기")
        await store.send(.yearSeasonDoneTapped).finish()

        #expect(store.state.isYearSeasonSheetPresented == false)
        #expect(store.state.yearSeasonChipTitle == "2026/분기")
        #expect(
            client.requests.last
                == .yearSeason(year: 2026, season: nil, genre: nil, lastId: nil, lastRank: nil))
    }

    @Test("R6·R7. 연도/분기·역대 다음 페이지는 마지막 순위를 커서로 보내고, 받는 중에도 막지 않는다")
    func rankCursor() async {
        let client = MockRankingClient([
            .success(
                RankingPage(
                    animes: [.sample(id: 1, rank: 1), .sample(id: 2, rank: 2)], lastId: 2,
                    lastValue: nil)),
            .success(page(3...3, lastId: 3)),
        ])
        let store = makeStore(client)
        await store.send(.filterTapped(.allTime)).finish()
        #expect(await waitUntil { store.state.items.count == 2 })

        await store.send(.genreResetTapped).finish()

        #expect(await waitUntil { client.requests.count == 2 })
        #expect(client.requests.last == .allTime(genre: nil, lastId: 2, lastRank: 2))
    }

    @Test("R9. 장르: 고르면 바로 표시, 완료하면 닫고 그 장르 이름으로 첫 페이지, 초기화는 목록을 비우지 않고 이어 받음")
    func genreSheet() async {
        let client = MockRankingClient([.success(page(1...2, lastId: 2, lastValue: "5"))])
        let store = makeStore(client)
        await store.send(.genreButtonTapped).finish()
        #expect(store.state.isGenreSheetPresented)

        await store.send(.genreTapped("코미디")).finish()
        #expect(store.state.selectedGenre == "코미디")
        await store.send(.genreDoneTapped).finish()
        #expect(store.state.isGenreSheetPresented == false)
        #expect(await waitUntil { store.state.items.count == 2 })

        await store.send(.genreResetTapped).finish()

        #expect(store.state.selectedGenre == "장르")
        #expect(await waitUntil { store.state.items.count == 4 })
        #expect(
            client.requests
                == [
                    .realTime(genre: "코미디", lastId: nil, lastValue: nil),
                    .realTime(genre: nil, lastId: 2, lastValue: "5"),
                ])
    }

    @Test("R9. 장르 시트를 X로 닫으면 고른 장르는 남고 요청하지 않는다")
    func genreSheetClose() async {
        let client = MockRankingClient([])
        let store = makeStore(client)
        await store.send(.genreButtonTapped).finish()
        await store.send(.genreTapped("액션")).finish()

        await store.send(.genreSheetPresentedChanged(false)).finish()

        #expect(store.state.selectedGenre == "액션")
        #expect(client.requests.isEmpty)
    }

    @Test("R1·R11. 검색은 홈 검색으로, 줄을 누르면 그 애니 상세로 간다 (id가 없으면 0)")
    func navigation() async {
        let store = makeStore(MockRankingClient([]))

        await store.send(.searchTapped).finish()
        await store.send(.itemTapped(.sample(id: 42, rank: 1))).finish()
        await store
            .send(
                .itemTapped(
                    RankedAnime(
                        animeId: nil, title: nil, coverImageUrl: nil, rank: nil, change: nil,
                        trend: nil, genres: nil))
            )
            .finish()

        #expect(
            navigator.actions
                == [
                    .push(HomeRoute.search), .push(DetailRoute.anime(id: 42)),
                    .push(DetailRoute.anime(id: 0)),
                ])
    }
}
