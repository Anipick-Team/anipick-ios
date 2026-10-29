import ClientCore
import DetailClientInterface
import DetailClientTesting
import DetailInterface
import FeatureTestSupport
import MVICore
import Testing

@testable import DetailFeature

/// 동작 목록 SD2~SD6·RC2~RC6 (notes/2026-10-30-R-detail-01-series-recommendations.md)과 1:1
@Suite("관련 작품·함께 볼만한 작품", .timeLimit(.minutes(1)))
struct AnimeListReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockDetailClient()

    private func makeStore(_ kind: AnimeListReducer.Kind) -> Store<AnimeListReducer> {
        return Store(
            initialState: .init(kind: kind, animeId: 7, animeTitle: "원피스"),
            reducer: AnimeListReducer(detailClient: client, navigator: navigator))
    }

    private func series(_ ids: [Int], count: Int = 20, lastId: Int?) -> Result<
        SeriesPage?, TransportError
    > {
        return .success(SeriesPage(animes: ids.map { .sample($0) }, count: count, lastId: lastId))
    }

    private func recommended(_ ids: [Int], title: String?, lastId: Int?)
        -> Result<AnimeRecommendationPage?, TransportError>
    {
        return .success(
            AnimeRecommendationPage(
                animes: ids.map { .sample($0) }, referenceAnimeTitle: title, lastId: lastId))
    }

    @Test("SD2. 관련 작품: 보일 때마다 커서를 비우고 첫 페이지로 바꾼다 (개수·커서 갱신)")
    func seriesAppears() async {
        client.stubSeries([
            series([1, 2], count: 12, lastId: 2), series([3], count: 13, lastId: 3),
        ])
        let store = makeStore(.series)

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [3])
        #expect(store.state.count == 13)
        #expect(
            client.requests == [.series(animeId: 7, lastId: nil), .series(animeId: 7, lastId: nil)])
    }

    @Test("SD3. 마지막 칸이 보이면 커서로 이어 붙인다. 커서가 없어도 받는다 (레거시 그대로)")
    func seriesLoadsMore() async {
        client.stubSeries([series([1, 2], lastId: 2), series([3], lastId: nil)])
        let store = makeStore(.series)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()
        await store.send(.itemAppeared(.sample(3))).finish()

        #expect(store.state.items.map(\.animeId) == [1, 2, 3, 3])
        #expect(
            client.requests.suffix(2) == [
                .series(animeId: 7, lastId: 2), .series(animeId: 7, lastId: nil),
            ])
    }

    @Test(
        "SD4·RC4. 실패하거나 결과가 없으면 그대로", arguments: [AnimeListReducer.Kind.series, .recommendations])
    func failure(kind: AnimeListReducer.Kind) async {
        client.stubSeries([series([1], lastId: 1), .failure(.offline), .success(nil)])
        client.stubRecommendations([
            recommended([1], title: "t", lastId: 1), .failure(.offline), .success(nil),
        ])
        let store = makeStore(kind)
        await store.send(.appeared).finish()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [1])
    }

    @Test("RC2. 함께 볼만한 작품: 보일 때마다 지금 커서로 이어 받고(중복 animeId는 뺀다), 제목을 기준 제목으로(없으면 -)")
    func recommendations() async {
        client.stubRecommendations([
            recommended([1, 2], title: "나루토", lastId: 2),
            recommended([2, 3], title: nil, lastId: 3),
        ])
        let store = makeStore(.recommendations)

        await store.send(.appeared).finish()
        #expect(store.state.bannerText == "'나루토'와\n 함께보기 좋은 작품")
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [1, 2, 3])
        #expect(store.state.animeTitle == "-")
        #expect(
            client.requests == [
                .recommendations(animeId: 7, lastId: nil), .recommendations(animeId: 7, lastId: 2),
            ])
    }

    @Test("RC3. 마지막 칸이 보이면 이어 받는다")
    func recommendationsLoadMore() async {
        client.stubRecommendations([recommended([1, 2], title: "t", lastId: 2)])
        let store = makeStore(.recommendations)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()

        #expect(client.requests.count == 2)
    }

    @Test(
        "SD5·RC5. 제목·배너 문구",
        arguments: [
            (AnimeListReducer.Kind.series, "관련 작품", "원피스 의\n 관련 작품이에요!"),
            (.recommendations, "함께 볼만한 작품", "'원피스'와\n 함께보기 좋은 작품"),
        ])
    func texts(kind: AnimeListReducer.Kind, header: String, banner: String) {
        let state = AnimeListReducer.State(kind: kind, animeId: 1, animeTitle: "원피스")
        #expect(state.headerTitle == header)
        #expect(state.bannerText == banner)
    }

    @Test("SD6·RC6. 칸은 상세로(id가 없으면 0), 뒤로는 pop")
    func navigation() async {
        let store = makeStore(.series)

        await store.send(.itemTapped(.sample(4))).finish()
        await store.send(.itemTapped(DetailAnime(animeId: nil, title: nil, coverImageUrl: nil)))
            .finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions == [
                .push(DetailRoute.anime(id: 4)), .push(DetailRoute.anime(id: 0)), .pop,
            ])
    }
}
