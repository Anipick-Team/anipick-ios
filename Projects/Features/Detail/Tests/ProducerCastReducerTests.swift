import ClientCore
import DetailClientInterface
import DetailClientTesting
import DetailInterface
import FeatureTestSupport
import MVICore
import Testing

@testable import DetailFeature

/// 동작 목록 PR2~PR6·CV2~CV4 (notes/2026-10-30-R-detail-02-producer-cast.md)과 1:1
@Suite("제작사·캐릭터/성우진", .timeLimit(.minutes(1)))
struct ProducerCastReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockDetailClient()

    private func producer() -> Store<ProducerReducer> {
        return Store(
            initialState: .init(studioId: 3),
            reducer: ProducerReducer(detailClient: client, navigator: navigator))
    }

    private func page(_ animes: [StudioAnime], lastId: Int?, lastValue: String? = nil)
        -> Result<StudioPage, TransportError>
    {
        return .success(
            StudioPage(studioName: "MAPPA", animes: animes, lastId: lastId, lastValue: lastValue))
    }

    @Test("PR2. 보일 때마다 지금 커서로 받아 이름을 쓰고 연도별로 합친다 (연도 내림차순)")
    func appears() async {
        client.stubStudio([
            page([.sample(1, year: "2023"), .sample(2, year: "2024")], lastId: 2, lastValue: "v"),
            page([.sample(3, year: "2023")], lastId: 3),
        ])
        let store = producer()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.studioName == "MAPPA")
        #expect(store.state.groups.map(\.year) == ["2024", "2023"])
        #expect(store.state.groups[1].animes.map(\.animeId) == [1, 3])
        #expect(
            client.requests == [
                .studio(id: 3, lastId: nil, lastValue: nil),
                .studio(id: 3, lastId: 2, lastValue: "v"),
            ])
    }

    @Test("PR3. 합칠 때 이미 있는 animeId는 뺀다 (id가 없는 작품은 그대로, 숫자가 아닌 연도는 맨 뒤)")
    func merge() {
        let groups = ProducerReducer.merge(
            [ProducerReducer.YearGroup(year: "2024", animes: [.sample(1, year: "2024")])],
            [
                .sample(1, year: "2024"),
                StudioAnime(animeId: nil, title: nil, coverImageUrl: nil, seasonYear: "2024"),
                .sample(2, year: "미정"), .sample(3, year: "2025"),
            ])

        #expect(groups.map(\.year) == ["2025", "2024", "미정"])
        #expect(groups[1].animes.map(\.animeId) == [1, nil])
    }

    @Test("PR4. 서버 커서와 같은 작품이 보이면 다음 페이지 (다른 작품은 무시)")
    func loadsMore() async {
        client.stubStudio([page([.sample(1, year: "2024"), .sample(2, year: "2024")], lastId: 2)])
        let store = producer()
        await store.send(.appeared).finish()

        await store.send(.animeAppeared(.sample(1, year: "2024"))).finish()
        await store.send(.animeAppeared(.sample(2, year: "2024"))).finish()

        #expect(client.requests.count == 2)
    }

    @Test("PR5. 실패하면 그대로")
    func producerFailure() async {
        client.stubStudio([.failure(.decoding)])
        let store = producer()

        await store.send(.appeared).finish()

        #expect(store.state.studioName == "")
        #expect(store.state.groups.isEmpty)
    }

    @Test("PR6. 작품은 상세로, 뒤로는 pop")
    func producerNavigation() async {
        let store = producer()

        await store.send(.animeTapped(.sample(5, year: "2024"))).finish()
        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.push(DetailRoute.anime(id: 5)), .pop])
    }

    @Test("CV2. 처음 보일 때 한 번만 받는다. 실패하면 그대로")
    func castLoadsOnce() async {
        client.stubCharacters(.success([.sample(1), .sample(2)]))
        let store = Store(
            initialState: CastReducer.State(animeId: 7),
            reducer: CastReducer(detailClient: client, navigator: navigator))

        await store.send(.appeared).finish()
        client.stubCharacters(.failure(.offline))
        await store.send(.appeared).finish()

        #expect(store.state.cast.count == 2)
        #expect(client.requests == [.characters(animeId: 7)])
    }

    @Test("CV3·CV4. 칸을 누르면 성우 상세로(성우가 없으면 0), 뒤로는 pop")
    func castNavigation() async {
        let store = Store(
            initialState: CastReducer.State(animeId: 7),
            reducer: CastReducer(detailClient: client, navigator: navigator))

        await store.send(.memberTapped(.sample(1))).finish()
        await store.send(.memberTapped(CastMember(character: nil, voiceActor: nil))).finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions == [
                .push(DetailRoute.voiceActor(id: 101)), .push(DetailRoute.voiceActor(id: 0)), .pop,
            ])
    }
}
