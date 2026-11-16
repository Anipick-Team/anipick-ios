import Analytics
import ClientCore
import ExploreClientInterface
import ExploreClientTesting
import FeatureTestSupport
import MVICore
import MetadataClientInterface
import MetadataClientTesting
import ReviewClientInterface
import ReviewClientTesting
import Testing
import os

@testable import AuthFeature

/// 동작 목록 PS1~PS14 (notes/2026-10-30-R-auth-04-preference.md)과 1:1
@Suite("취향 선택", .timeLimit(.minutes(1)))
struct PreferenceReducerTests {
    private let tracker = RecordingTracker()
    private let completed = OSAllocatedUnfairLock(initialState: 0)
    private let metadata = MockMetadataClient(
        genres: [Genre(id: 3, name: "SF"), Genre(id: 4, name: "액션")], seasonYears: [2026, 2025])

    private func page(_ ids: [Int], lastId: Int?) -> Result<OnboardingPage?, TransportError> {
        return .success(OnboardingPage(animes: ids.map { .sample($0) }, lastId: lastId))
    }

    private func makeStore(
        _ explore: MockExploreClient = MockExploreClient(),
        review: MockReviewClient = MockReviewClient()
    ) -> Store<PreferenceReducer> {
        return Store(
            initialState: PreferenceReducer.State(genres: [], seasonYears: []),
            reducer: PreferenceReducer(
                exploreClient: explore, reviewClient: review, metadataClient: metadata,
                analytics: tracker,
                onLoginCompleted: { [completed] in completed.withLock { $0 += 1 } },
                firstLoadDelay: .milliseconds(10))
        )
    }

    private func request(
        query: String? = nil, year: Int? = nil, season: Int? = nil, genreId: Int? = nil,
        lastId: Int? = nil
    ) -> MockExploreClient.Request {
        return .init(query: query, year: year, season: season, genreId: genreId, lastId: lastId)
    }

    @Test("PS2. 보이면 메타데이터를 다시 받아 장르·연도를 바꾸고, 잠시 뒤 첫 목록을 받는다")
    func appears() async {
        let explore = MockExploreClient(page([1, 2], lastId: 2))
        let store = makeStore(explore)

        await store.send(.appeared).finish()

        #expect(store.state.genres.map(\.name) == ["SF", "액션"])
        #expect(store.state.seasonYears == ["2026", "2025"])
        #expect(await waitUntil { store.state.animes.count == 2 })
        #expect(explore.requests == [request()])
        #expect(store.state.lastId == 2)
    }

    @Test("PS3. 마지막 칸이 보이면 커서로 이어 받는다 (받는 중인지 보지 않음)")
    func loadsMore() async {
        let explore = MockExploreClient(page([1, 2], lastId: 2))
        let store = makeStore(explore)
        await store.send(.firstLoadTimerFired).finish()

        await store.send(.itemAppeared(.sample(1))).finish()
        await store.send(.itemAppeared(.sample(2))).finish()

        #expect(explore.requests == [request(), request(lastId: 2)])
    }

    @Test("PS4. 검색: 처음부터 다시 받는다. 지우기는 검색어를 비우고 다시 받는다")
    func search() async {
        let explore = MockExploreClient(page([1], lastId: 1))
        let store = makeStore(explore)
        await store.send(.firstLoadTimerFired).finish()

        await store.send(.queryChanged("나루토")).finish()
        await store.send(.searchRequested).finish()
        await store.send(.clearSearchTapped).finish()

        #expect(explore.requests == [request(), request(query: "나루토"), request()])
        #expect(store.state.animes.map(\.animeId) == [1])
    }

    @Test(
        "PS5·PS6. 필터: 칩은 탭을 바꾸고 시트를 연다. 장르는 이름으로 id, 연도·분기는 숫자로(전체는 뺌). 완료는 커서를 비우고, X는 커서를 남긴 채 다시 받는다"
    )
    func filters() async {
        let explore = MockExploreClient(page([1], lastId: 9))
        let store = makeStore(explore)
        await store.send(.metadataRefreshedForTest).finish()
        await store.send(.firstLoadTimerFired).finish()

        await store.send(.filterChipTapped(.yearQuarter)).finish()
        #expect(store.state.isFilterSheetPresented)
        #expect(store.state.filterTab == .yearQuarter)
        await store.send(.yearChanged("2025")).finish()
        await store.send(.quarterChanged("전체")).finish()
        await store.send(.genreSelected("SF")).finish()
        await store.send(.filterCloseTapped).finish()
        await store.send(.filterChipTapped(.genre)).finish()
        await store.send(.quarterChanged("2")).finish()
        await store.send(.filterDoneTapped).finish()

        #expect(
            explore.requests
                == [
                    request(), request(year: 2025, genreId: 3, lastId: 9),
                    request(year: 2025, season: 2, genreId: 3),
                ])
        #expect(!store.state.isFilterSheetPresented)
    }

    @Test("PS7. 초기화는 고른 값과 커서만 비우고 다시 받지 않는다")
    func reset() async {
        let explore = MockExploreClient(page([1], lastId: 9))
        let store = makeStore(explore)
        await store.send(.firstLoadTimerFired).finish()
        await store.send(.yearChanged("2025")).finish()

        await store.send(.filterResetTapped).finish()

        #expect(store.state.selectedYear == "")
        #expect(store.state.lastId == nil)
        #expect(explore.requests.count == 1)
    }

    @Test("PS8·PS9·PS10. 칸을 누르면 별점 줄이 열리고 닫힌다. 평가하면 저장(같은 애니는 교체)하고 닫는다. 평가취소는 지운다")
    func ratings() async {
        let store = makeStore()

        await store.send(.animeTapped(1)).finish()
        #expect(store.state.openedRatingIds == [1])
        await store.send(.ratingSubmitted(animeId: 1, rating: 4)).finish()
        #expect(store.state.openedRatingIds.isEmpty)
        await store.send(.ratingSubmitted(animeId: 2, rating: 0)).finish()
        await store.send(.ratingChanged(animeId: 1, rating: 2.5)).finish()
        #expect(
            store.state.ratings == [.init(animeId: 1, rating: 2.5), .init(animeId: 2, rating: 0)])
        #expect(store.state.openedRatingIds == [2])

        await store.send(.ratingCancelTapped(1)).finish()

        #expect(store.state.ratings == [.init(animeId: 2, rating: 0)])
    }

    @Test("PS11·PS12. 완료: 별점을 한 번에 보내고(기다리지 않음) onboarding_complete(개수) 후 로그인 완료")
    func done() async {
        let review = MockReviewClient()
        let store = makeStore(review: review)
        await store.send(.ratingSubmitted(animeId: 1, rating: 4)).finish()
        await store.send(.ratingSubmitted(animeId: 5, rating: 3.5)).finish()

        await store.send(.doneTapped).finish()

        #expect(completed.withLock { $0 } == 1)
        #expect(tracker.events == [.onboardingComplete(ratedCount: 2)])
        #expect(
            await waitUntil {
                review.initialRatings
                    == [
                        [
                            InitialRating(animeId: 1, rating: 4),
                            InitialRating(animeId: 5, rating: 3.5),
                        ]
                    ]
            })
    }
}

extension PreferenceReducer.Intent {
    /// 테스트에서 메타데이터 갱신만 따로 반영한다
    static let metadataRefreshedForTest = PreferenceReducer.Intent.metadataRefreshed
}
