import ClientCore
import DetailInterface
import FeatureTestSupport
import MVICore
import MyInfoClientInterface
import MyInfoClientTesting
import ReviewClientTesting
import ReviewInterface
import Testing

@testable import MyInfoFeature

/// 동작 목록 RA1~RA13 (notes/2026-10-29-R-myinfo-02-rated.md)과 1:1
@Suite("평가한 작품", .timeLimit(.minutes(1)))
struct RatedReviewsReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: [Int], count: Int? = 30, lastId: Int? = 99, content: String? = "좋다")
        -> Result<RatedPage, TransportError>
    {
        return .success(
            RatedPage(
                count: count, lastId: lastId,
                reviews: ids.map {
                    .sample($0, content: content, rating: Double($0 % 5), likes: $0)
                }))
    }

    private func makeStore(
        _ pages: [Result<RatedPage, TransportError>],
        reviewClient: MockReviewClient = MockReviewClient()
    ) -> (Store<RatedReviewsReducer>, MockMyInfoClient) {
        let client = MockMyInfoClient(.init(ratedPages: pages))
        let store = Store(
            initialState: RatedReviewsReducer.State(),
            reducer: RatedReviewsReducer(
                myInfoClient: client, reviewClient: reviewClient, navigator: navigator,
                toastDuration: .milliseconds(50))
        )
        return (store, client)
    }

    @Test("RA1·RA2. 보일 때마다 커서 없이 첫 페이지를 받아 목록을 바꾸고, 총 개수와 커서(마지막 리뷰의 좋아요·별점)를 기억한다")
    func firstPage() async {
        let (store, client) = makeStore([page([1, 2, 3]), page([4])])

        await store.send(.appeared).finish()
        #expect(store.state.reviews.map(\.reviewId) == [1, 2, 3])
        #expect(store.state.totalCount == 30)
        #expect(store.state.lastId == 99)
        #expect(store.state.lastLikeCount == 3)
        #expect(store.state.lastRating == 3)
        await store.send(.appeared).finish()

        #expect(store.state.reviews.map(\.reviewId) == [4])
        #expect(
            client.requests
                == [
                    .ratedReviews(sort: .latest, lastId: nil, lastLikeCount: nil, lastRating: nil),
                    .ratedReviews(sort: .latest, lastId: nil, lastLikeCount: nil, lastRating: nil),
                ])
    }

    @Test("RA3. 정렬: 버튼으로 메뉴를 열고 닫고, 고르면 닫은 뒤 그 정렬로 첫 페이지")
    func sort() async {
        let (store, client) = makeStore([page([1])])
        await store.send(.sortButtonTapped).finish()
        #expect(store.state.isSortMenuPresented)

        await store.send(.sortSelected(.ratingDesc)).finish()

        #expect(store.state.isSortMenuPresented == false)
        #expect(store.state.sort == .ratingDesc)
        #expect(
            client.requests.last
                == .ratedReviews(
                    sort: .ratingDesc, lastId: nil, lastLikeCount: nil, lastRating: nil))
    }

    @Test("RA4. 마지막 칸이 보이고 7개 이상이면 커서로 다음 페이지. 6개 이하면 받지 않는다")
    func loadsMore() async {
        let (store, client) = makeStore([page(Array(1...7)), page([8, 9])])
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(store.state.reviews[5])).finish()
        await store.send(.itemAppeared(store.state.reviews[6])).finish()

        #expect(store.state.reviews.map(\.reviewId) == Array(1...9))
        #expect(
            client.requests.last
                == .ratedReviews(sort: .latest, lastId: 99, lastLikeCount: 7, lastRating: 2))

        let (small, smallClient) = makeStore([page(Array(1...6))])
        await small.send(.appeared).finish()
        await small.send(.itemAppeared(small.state.reviews[5])).finish()
        #expect(smallClient.requests.count == 1)
    }

    @Test("RA5. 목록이 움직이면 리뷰 메뉴를, 스크롤 위치가 바뀌면 정렬 메뉴를 닫는다")
    func scrollClosesMenus() async {
        let (store, _) = makeStore([page([1])])
        await store.send(.moreTapped(.sample(1))).finish()
        await store.send(.sortButtonTapped).finish()

        await store.send(.scrolled).finish()
        #expect(store.state.isReviewMenuPresented == false)
        #expect(store.state.isSortMenuPresented)
        await store.send(.sortMenuClosedByScroll).finish()
        #expect(store.state.isSortMenuPresented == false)
    }

    @Test("RA6. 리뷰만 보기: 켜고 첫 페이지를 받아 내용이 비었거나 없는 것은 뺀다")
    func reviewOnly() async {
        let reviews: [RatedReview] = [
            .sample(1, content: "있음"), .sample(2, content: ""), .sample(3, content: nil),
        ]
        let (store, client) = makeStore([.success(RatedPage(count: 3, lastId: 3, reviews: reviews))]
        )

        await store.send(.reviewOnlyTapped).finish()

        #expect(store.state.isReviewOnly)
        #expect(store.state.reviews.map(\.reviewId) == [1])
        #expect(client.requests.count == 1)
    }

    @Test("RA7. 다음 페이지에서 이미 있는 리뷰는 빼고 붙인다")
    func dropsDuplicates() async {
        let (store, _) = makeStore([page(Array(1...7)), page([7, 8])])
        await store.send(.appeared).finish()

        await store.send(.itemAppeared(store.state.reviews[6])).finish()

        #expect(store.state.reviews.map(\.reviewId) == Array(1...8))
    }

    @Test("RA8·RA11. 칸을 누르면 상세로, 메뉴의 수정은 메뉴를 닫고 그 리뷰의 별점·내용으로 리뷰 작성으로")
    func navigation() async {
        let (store, _) = makeStore([])
        let review = RatedReview.sample(3, content: "수정할 리뷰", rating: 3.5)

        await store.send(.cellTapped(review)).finish()
        await store.send(.moreTapped(review)).finish()
        #expect(store.state.isReviewMenuPresented)
        await store.send(.editTapped).finish()

        #expect(store.state.isReviewMenuPresented == false)
        #expect(
            navigator.actions
                == [
                    .push(DetailRoute.anime(id: 30)),
                    .push(ReviewRoute.write(animeId: 30, rating: 3.5, content: "수정할 리뷰")),
                ])
    }

    @Test("RA9·RA10. 삭제: 메뉴를 닫고 안내를 띄우고 삭제를 보낸다. 성공하면 첫 페이지를 다시 받고, 안내는 정해진 시간 뒤 사라진다")
    func delete() async {
        let reviewClient = MockReviewClient()
        let (store, client) = makeStore([page([1, 2]), page([2])], reviewClient: reviewClient)
        await store.send(.appeared).finish()
        await store.send(.moreTapped(store.state.reviews[0])).finish()

        let effect = store.send(.deleteTapped)
        #expect(store.state.isReviewMenuPresented == false)
        #expect(store.state.isDeleteToastPresented)
        await effect.finish()

        #expect(reviewClient.deletedIds == [1])
        #expect(await waitUntil { store.state.reviews.map(\.reviewId) == [2] })
        #expect(client.requests.count == 2)
        #expect(await waitUntil { !store.state.isDeleteToastPresented })
    }

    @Test("RA9. 삭제에 실패해도 안내는 뜨고, 목록은 다시 받지 않는다")
    func deleteFailure() async {
        let reviewClient = MockReviewClient(result: .failure(.offline))
        let (store, client) = makeStore([page([1])], reviewClient: reviewClient)
        await store.send(.appeared).finish()
        await store.send(.moreTapped(store.state.reviews[0])).finish()

        await store.send(.deleteTapped).finish()

        #expect(reviewClient.deletedIds == [1])
        #expect(client.requests.count == 1)
    }

    @Test("RA12. 리뷰를 저장했다는 알림을 받으면 첫 페이지를 다시 받는다")
    func reloads() async {
        let (store, client) = makeStore([page([1])])

        await store.send(.reloadRequested).finish()

        #expect(client.requests.count == 1)
    }

    @Test("RA13. 화면을 떠나면 안내를 닫는다. 뒤로는 pop")
    func disappear() async {
        let (store, _) = makeStore([])
        await store.send(.moreTapped(.sample(1))).finish()
        _ = store.send(.deleteTapped)

        await store.send(.disappeared).finish()
        await store.send(.backTapped).finish()

        #expect(store.state.isDeleteToastPresented == false)
        #expect(navigator.actions == [.pop])
    }
}
