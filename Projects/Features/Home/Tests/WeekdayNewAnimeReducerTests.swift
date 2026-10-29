import ClientCore
import DetailInterface
import FeatureTestSupport
import Foundation
import HomeClientInterface
import HomeClientTesting
import MVICore
import Testing

@testable import HomeFeature

/// 동작 목록 WN2~WN9 (notes/2026-10-30-R-home-02-coming-soon-weekday.md)과 1:1
@Suite("요일별 신작", .timeLimit(.minutes(1)))
struct WeekdayNewAnimeReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: [Int?], lastId: Int?) -> Result<WeekdayAnimePage, TransportError> {
        return .success(
            WeekdayAnimePage(
                animes: ids.map { HomeAnime(animeId: $0, title: nil, coverImageUrl: nil) },
                lastId: lastId))
    }

    private func makeStore(_ client: MockHomeClient, day: WeekdayNewAnimeDay = .tuesday)
        -> Store<WeekdayNewAnimeReducer>
    {
        return Store(
            initialState: .init(day: day),
            reducer: WeekdayNewAnimeReducer(homeClient: client, navigator: navigator))
    }

    @Test("WN2. 처음 보일 때 한 번만 받는다. 받는 동안 목록을 비우고 받는 중 표시")
    func loadsOnce() async {
        let client = MockHomeClient()
        client.stubWeekday([page([1, 2], lastId: 2)])
        let store = makeStore(client)

        let effect = store.send(.appeared)
        #expect(store.state.isLoading)
        await effect.finish()
        await store.send(.appeared).finish()

        #expect(!store.state.isLoading)
        #expect(store.state.animes.map(\.animeId) == [1, 2])
        #expect(client.requests == [.weekday(day: "TUE", sort: "popularity", lastId: nil)])
    }

    @Test("WN3. 요일·정렬을 바꾸면 처음부터. 같은 값이면 받지 않는다")
    func selection() async {
        let client = MockHomeClient()
        client.stubWeekday([page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.daySelected(.tuesday)).finish()
        await store.send(.daySelected(.sunday)).finish()
        await store.send(.sortSelected(.popular)).finish()
        await store.send(.sortSelected(.latest)).finish()

        #expect(
            client.requests
                == [
                    .weekday(day: "TUE", sort: "popularity", lastId: nil),
                    .weekday(day: "SUN", sort: "popularity", lastId: nil),
                    .weekday(day: "SUN", sort: "latest", lastId: nil),
                ])
    }

    @Test("WN4. 스와이프로 앞·뒤 요일. 월요일 앞과 일요일 뒤로는 가지 않는다")
    func swipe() async {
        let client = MockHomeClient()
        let store = makeStore(client, day: .monday)

        await store.send(.swipedToPreviousDay).finish()
        #expect(store.state.day == .monday)
        await store.send(.swipedToNextDay).finish()
        #expect(store.state.day == .tuesday)

        let sunday = makeStore(client, day: .sunday)
        await sunday.send(.swipedToNextDay).finish()
        #expect(sunday.state.day == .sunday)
        #expect(client.requests == [.weekday(day: "TUE", sort: "popularity", lastId: nil)])
    }

    @Test("WN5. 응답이 오기 전에 요일·정렬이 바뀌면 그 응답은 버린다 (받는 중 표시도 그대로)")
    func dropsStale() async {
        let client = MockHomeClient(delay: .milliseconds(50))
        client.stubWeekday([page([2], lastId: 2)])
        let store = makeStore(client)

        let current = store.send(.daySelected(.friday))
        await store.send(
            .loaded(.tuesday, .popular, WeekdayAnimePage(animes: [.sample(1)], lastId: 1))
        ).finish()
        await store.send(
            .moreLoaded(.friday, .latest, WeekdayAnimePage(animes: [.sample(3)], lastId: 3))
        ).finish()
        #expect(store.state.isLoading)
        #expect(store.state.animes.isEmpty)
        await current.finish()

        #expect(store.state.animes.map(\.animeId) == [2])
        #expect(!store.state.isLoading)
    }

    @Test("WN6. 마지막 칸에서 커서로 이어 받는다. 겹치는 id는 빼고(id 없는 칸은 붙임), 빈 페이지·같은 커서·커서 없음이면 끝")
    func loadsMore() async {
        let client = MockHomeClient()
        client.stubWeekday([
            page([1, 2], lastId: 2), page([2, nil, 3], lastId: 3), page([], lastId: 4),
        ])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(HomeAnime(animeId: 1, title: nil, coverImageUrl: nil)))
            .finish()
        await store.send(.itemAppeared(HomeAnime(animeId: 2, title: nil, coverImageUrl: nil)))
            .finish()
        #expect(store.state.animes.map(\.animeId) == [1, 2, nil, 3])
        #expect(store.state.hasMore)
        await store.send(.itemAppeared(HomeAnime(animeId: 3, title: nil, coverImageUrl: nil)))
            .finish()

        #expect(!store.state.hasMore)
        #expect(
            client.requests.suffix(2) == [
                .weekday(day: "TUE", sort: "popularity", lastId: 2),
                .weekday(day: "TUE", sort: "popularity", lastId: 3),
            ])
    }

    @Test("WN7. 첫 페이지 커서가 없으면 더 받지 않는다. 받는 중이면 다시 받지 않는다")
    func noCursor() async {
        let client = MockHomeClient()
        client.stubWeekday([page([1], lastId: nil)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(HomeAnime(animeId: 1, title: nil, coverImageUrl: nil)))
            .finish()

        #expect(!store.state.hasMore)
        #expect(client.requests.count == 1)
    }

    @Test("WN8. 실패하면 받는 중만 끝낸다")
    func failure() async {
        let client = MockHomeClient()
        client.stubWeekday([.failure(.offline)])
        let store = makeStore(client)

        await store.send(.appeared).finish()

        #expect(!store.state.isLoading)
        #expect(store.state.animes.isEmpty)
    }

    @Test("WN9. 칸은 상세로, 뒤로는 pop. 요일 계산은 일요일=7")
    func navigationAndDay() async {
        let store = makeStore(MockHomeClient())

        await store.send(.itemTapped(.sample(8))).finish()
        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.push(DetailRoute.anime(id: 8)), .pop])
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        // 2026-11-01은 일요일, 11-02는 월요일
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        #expect(WeekdayNewAnimeDay.of(sunday, calendar: calendar) == .sunday)
        #expect(
            WeekdayNewAnimeDay.of(sunday.addingTimeInterval(86_400), calendar: calendar) == .monday)
    }
}
