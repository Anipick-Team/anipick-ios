import ClientCore
import DetailInterface
import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import HomeInterface
import MVICore
import Testing
import os

@testable import HomeFeature

/// 동작 목록 HM3~HM13 (notes/2026-10-30-R-home-05-main.md)과 1:1
@Suite("홈 메인", .timeLimit(.minutes(1)))
struct HomeMainReducerTests {
    private let navigator = RecordingNavigator()
    private let lastVisited = OSAllocatedUnfairLock(initialState: 0)
    private let tabs = OSAllocatedUnfairLock<[String]>(initialState: [])

    private func page(_ ids: [Int], title: String?) -> RecommendationPage {
        return RecommendationPage(
            animes: ids.map { .sample($0) }, referenceAnimeTitle: title, lastId: nil, lastValue: nil
        )
    }

    private func makeStore(_ client: MockHomeClient, day: WeekdayNewAnimeDay = .monday) -> Store<
        HomeMainReducer
    > {
        return Store(
            initialState: .init(selectedWeekday: day),
            reducer: HomeMainReducer(
                homeClient: client, navigator: navigator, cachedNickname: { "하노" },
                lastVisitedAnimeId: { [lastVisited] in lastVisited.withLock { $0 } },
                showRanking: { [tabs] in tabs.withLock { $0.append("ranking") } },
                showExplore: { [tabs] year, season in
                    tabs.withLock { $0.append("explore \(year)-\(season)") }
                }))
    }

    private func fullStub() -> MockHomeClient.HomeStub {
        return MockHomeClient.HomeStub(
            trending: .success([TrendingAnime(animeId: 1, title: "T", coverImageUrl: nil, rank: 1)]
            ),
            recommendations: .success(page([2], title: nil)),
            recentRecommendations: .success(page([3], title: "원피스")),
            recentReviews: .success([
                HomeReview(
                    reviewId: 4, animeTitle: "A", reviewContent: "C", nickname: "N", createdAt: nil)
            ]),
            upcoming: .success(UpcomingSeason(season: 1, seasonYear: 2027, animes: [.sample(5)])),
            comingSoon: .success([.sample(6)]))
    }

    @Test("HM3. 본 작품이 없으면: 비슷한 작품을 비우고, 취향 추천을 두 번 받는다. 이어서 다섯 섹션을 차례로")
    func appearsWithoutVisited() async {
        let client = MockHomeClient()
        client.stubHome(fullStub())
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(await waitUntil { client.requests.last == .homeComingSoon })

        #expect(store.state.nickname == "하노")
        #expect(store.state.similar.isEmpty)
        #expect(store.state.recommendations.map(\.animeId) == [2])
        #expect(client.requests.filter { $0 == .homeRecommendations }.count == 2)
        #expect(
            client.requests.filter { $0 != .homeRecommendations }
                == [
                    .trending, .weekday(day: "MON", sort: "popularity", lastId: nil, size: 6),
                    .homeRecentReviews,
                    .upcomingSeason, .homeComingSoon,
                ])
        #expect(await waitUntil { store.state.comingSoon.map(\.animeId) == [6] })
        #expect(store.state.trending.count == 1)
        #expect(store.state.recentReviews.count == 1)
        #expect([store.state.seasonYear, store.state.season] == [2027, 1])
    }

    @Test("HM4. 본 작품이 있으면: 그 작품의 비슷한 작품을 (결과를 안 쓰는 것까지) 두 번, 취향 추천은 한 번")
    func appearsWithVisited() async {
        lastVisited.withLock { $0 = 9 }
        let client = MockHomeClient()
        client.stubHome(fullStub())
        let store = makeStore(client)

        await store.send(.appeared).finish()
        #expect(await waitUntil { client.requests.last == .homeComingSoon })

        #expect(client.requests.filter { $0 == .homeRecentRecommendations(animeId: 9) }.count == 2)
        #expect(client.requests.filter { $0 == .homeRecommendations }.count == 1)
        #expect(await waitUntil { store.state.hasRecentSimilar })
        #expect(store.state.similarTitle == "원피스")
    }

    @Test("HM3. 본 작품 기록이 지워지면 보일 때 비슷한 작품을 곧바로 비운다 (요청 없이)")
    func clearsSimilarWithoutVisited() async {
        lastVisited.withLock { $0 = 9 }
        let client = MockHomeClient()
        client.stubHome(fullStub())
        let store = makeStore(client)
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.hasRecentSimilar })

        lastVisited.withLock { $0 = 0 }
        let effect = store.send(.appeared)

        #expect(store.state.similar.isEmpty)
        #expect(store.state.similarTitle == "")
        await effect.finish()
    }

    @Test("HM5. 비슷한 작품: 결과가 없으면 비우고, 실패하면 그대로")
    func similarFailure() async {
        lastVisited.withLock { $0 = 9 }
        let client = MockHomeClient()
        var stub = fullStub()
        client.stubHome(stub)
        let store = makeStore(client)
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.hasRecentSimilar })

        stub.recentRecommendations = .failure(.offline)
        client.stubHome(stub)
        await store.send(.appeared).finish()
        #expect(await waitUntil { client.requests.filter { $0 == .homeComingSoon }.count == 2 })
        #expect(store.state.hasRecentSimilar)

        stub.recentRecommendations = .success(nil)
        client.stubHome(stub)
        await store.send(.appeared).finish()
        #expect(await waitUntil { !store.state.hasRecentSimilar })
    }

    @Test("HM6. 섹션 하나가 실패해도 다음 섹션을 받고, 실패한 섹션은 그대로 둔다")
    func continuesAfterFailure() async {
        let client = MockHomeClient()
        var stub = fullStub()
        stub.trending = .failure(.offline)
        stub.recentReviews = .failure(.decoding)
        stub.upcoming = .failure(.server(status: 500))
        client.stubHome(stub)
        let store = makeStore(client)

        await store.send(.appeared).finish()

        #expect(await waitUntil { store.state.comingSoon.count == 1 })
        #expect(store.state.trending.isEmpty)
        #expect(store.state.recentReviews.isEmpty)
        #expect(store.state.season == 0)
    }

    @Test("HM7. 요일을 바꾸면 목록을 비우고 그 요일 6개를 받는다. 같은 요일이면 받지 않는다. 지난 응답은 버린다")
    func weekday() async {
        let client = MockHomeClient()
        client.stubWeekday([.success(WeekdayAnimePage(animes: [.sample(7)], lastId: nil))])
        let store = makeStore(client)

        await store.send(.weekdaySelected(.monday)).finish()
        #expect(client.requests.isEmpty)
        await store.send(.weekdaySelected(.friday)).finish()
        #expect(store.state.weekdayAnimes.map(\.animeId) == [7])
        await store.send(.weekdayLoaded(.monday, [.sample(8)], chained: false)).finish()

        #expect(store.state.weekdayAnimes.map(\.animeId) == [7])
        #expect(client.requests == [.weekday(day: "FRI", sort: "popularity", lastId: nil, size: 6)])
    }

    @Test(
        "HM8~HM13. 섹션 이동: 검색·상세·추천(기준 제목)·요일(선택 요일)·최근 리뷰·비슷한 작품(본 작품 id)·공개 예정, 랭킹·방영 예정은 App 탭으로")
    func navigation() async {
        lastVisited.withLock { $0 = 11 }
        let client = MockHomeClient()
        var stub = fullStub()
        stub.recommendations = .success(page([2], title: "나루토"))
        client.stubHome(stub)
        let store = makeStore(client, day: .wednesday)
        await store.send(.appeared).finish()
        #expect(await waitUntil { store.state.season == 1 && store.state.referenceTitle == "나루토" })

        for intent: HomeMainReducer.Intent in [
            .searchTapped, .animeTapped(animeId: 3), .animeTapped(animeId: nil),
            .recommendationsTapped, .weekdayTapped,
            .recentReviewsTapped, .similarTapped, .comingSoonTapped, .rankingTapped,
            .upcomingTapped,
        ] {
            await store.send(intent).finish()
        }

        #expect(
            navigator.actions
                == [
                    .push(HomeRoute.search), .push(DetailRoute.anime(id: 3)),
                    .push(DetailRoute.anime(id: 0)),
                    .push(HomeRoute.recommendations(animeId: 0, animeTitle: "나루토")),
                    .push(HomeRoute.weekdayNewAnime(day: 3)), .push(HomeRoute.recentReviews),
                    .push(HomeRoute.similarRecommendations(animeId: 11)),
                    .push(HomeRoute.comingSoon),
                ])
        #expect(tabs.withLock { $0 } == ["ranking", "explore 2027-1"])
    }

    @Test("HM14. 리뷰 날짜: yyyy-MM-dd 꼴이면 앞 10자를 점으로, 아니면 그대로, 없으면 --")
    func reviewDate() {
        #expect(HomeMainView.reviewDateText("2026-10-30T12:00:00") == "2026.10.30")
        #expect(HomeMainView.reviewDateText("2026.10.30") == "2026.10.30")
        #expect(HomeMainView.reviewDateText("3일 전") == "3일 전")
        #expect(HomeMainView.reviewDateText(nil) == "--")
    }
}
