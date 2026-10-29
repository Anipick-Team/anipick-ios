import ClientCore
import DetailInterface
import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import MVICore
import Testing

@testable import HomeFeature

/// 동작 목록 RL1~RL8 (notes/2026-10-30-R-home-01-recommendations.md)과 1:1
@Suite("추천 목록", .timeLimit(.minutes(1)))
struct RecommendationListReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockHomeClient()

    private func page(_ ids: [Int], lastId: Int?, lastValue: String? = nil, title: String? = nil)
        -> Result<RecommendationPage?, TransportError>
    {
        return .success(
            RecommendationPage(
                animes: ids.map { .sample($0) }, referenceAnimeTitle: title, lastId: lastId,
                lastValue: lastValue))
    }

    private func makeStore(_ kind: RecommendationListReducer.Kind, nickname: String = "하노")
        -> Store<RecommendationListReducer>
    {
        return Store(
            initialState: .init(kind: kind, nickname: nickname),
            reducer: RecommendationListReducer(homeClient: client, navigator: navigator))
    }

    @Test("RL1. 취향 추천: 보일 때마다 지금 커서로 받아 목록을 **바꾼다** (lastValue는 보내지 않는다)")
    func forYouReplaces() async {
        client.stubRecommendations([page([1, 2], lastId: 2, lastValue: "v"), page([3], lastId: 3)])
        let store = makeStore(.forYou(animeTitle: nil))

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [3])
        #expect(store.state.lastValue == nil)
        #expect(
            client.requests == [
                .recommendations(lastId: nil, lastValue: nil),
                .recommendations(lastId: 2, lastValue: nil),
            ])
    }

    @Test("RL2. 비슷한 작품: 기준 작품으로 받아 이어 붙이고 기준 제목·커서(lastValue 포함)를 갱신한다")
    func similarAppends() async {
        client.stubRecommendations([
            page([1], lastId: 1, lastValue: "a", title: "원피스"),
            page([2], lastId: 2, lastValue: "b"),
        ])
        let store = makeStore(.similar(animeId: 9))

        await store.send(.appeared).finish()
        #expect(store.state.bannerText == "최근 찾아보신 원피스과\n비슷한 작품이에요")
        await store.send(.itemAppeared(.sample(1))).finish()

        #expect(store.state.items.map(\.animeId) == [1, 2])
        #expect(store.state.referenceTitle == "--")
        #expect(
            client.requests
                == [
                    .recentRecommendations(animeId: 9, lastId: nil, lastValue: nil),
                    .recentRecommendations(animeId: 9, lastId: 1, lastValue: "a"),
                ])
    }

    @Test("RL3. 기준 작품이 없으면 취향 추천 요청으로 이어 붙이고, lastValue는 갱신하지 않는다")
    func similarWithoutAnime() async {
        client.stubRecommendations([page([1], lastId: 1, lastValue: "a")])
        let store = makeStore(.similar(animeId: nil))

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [1, 1])
        #expect(store.state.lastValue == nil)
        #expect(
            client.requests == [
                .recommendations(lastId: nil, lastValue: nil),
                .recommendations(lastId: 1, lastValue: nil),
            ])
    }

    @Test("RL4. 마지막 칸이 보일 때만 받는다 (id가 없는 칸은 0으로 비교)")
    func loadsMoreAtLastItem() async {
        client.stubRecommendations([
            .success(
                RecommendationPage(
                    animes: [.sample(1), HomeAnime(animeId: nil, title: nil, coverImageUrl: nil)],
                    referenceAnimeTitle: nil,
                    lastId: nil, lastValue: nil))
        ])
        let store = makeStore(.similar(animeId: 9))
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(HomeAnime(animeId: nil, title: nil, coverImageUrl: nil)))
            .finish()

        #expect(client.requests.count == 1)
    }

    @Test("RL5. 실패하거나 결과가 없으면 아무것도 바꾸지 않는다")
    func failureChangesNothing() async {
        client.stubRecommendations([page([1], lastId: 1), .failure(.offline), .success(nil)])
        let store = makeStore(.forYou(animeTitle: "t"))
        await store.send(.appeared).finish()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.items.map(\.animeId) == [1])
        #expect(store.state.lastId == 1)
    }

    @Test(
        "RL6. 배너 문구: 제목이 있으면 그 제목, 없으면 닉네임",
        arguments: [
            (
                RecommendationListReducer.Kind.forYou(animeTitle: "나루토"),
                "나루토 을 재밌게 보셨다면,\n이 작품들도 마음에 드실거에요!"
            ),
            (.forYou(animeTitle: nil), "오늘의 추천작, 하노 님의\n취향에 맞춰 준비했어요!"),
            (.similar(animeId: 1), "최근 찾아보신 과\n비슷한 작품이에요"),
        ])
    func banner(kind: RecommendationListReducer.Kind, text: String) {
        #expect(makeStore(kind).state.bannerText == text)
    }

    @Test("RL7·RL8. 칸은 상세로(id가 없으면 0), 뒤로는 pop")
    func navigation() async {
        let store = makeStore(.forYou(animeTitle: nil))

        await store.send(.itemTapped(.sample(4))).finish()
        await store.send(.itemTapped(HomeAnime(animeId: nil, title: nil, coverImageUrl: nil)))
            .finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions == [
                .push(DetailRoute.anime(id: 4)), .push(DetailRoute.anime(id: 0)), .pop,
            ])
    }
}
