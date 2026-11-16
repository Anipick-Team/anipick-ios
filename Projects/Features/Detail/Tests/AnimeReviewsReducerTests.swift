import ClientCore
import CommunityClientTesting
import DetailClientTesting
import FeatureTestSupport
import Foundation
import MVICore
import ReviewClientInterface
import ReviewClientTesting
import ReviewInterface
import Testing

@testable import DetailFeature

/// 동작 목록 RT3~RT19 (notes/2026-10-30-R-detail-05-reviews.md)과 1:1
@Suite("애니 상세 (리뷰 탭)", .timeLimit(.minutes(1)))
struct AnimeReviewsReducerTests {
    private let navigator = RecordingNavigator()
    private let reviews = MockReviewClient()

    private func makeStore() -> Store<AnimeDetailReducer> {
        return Store(
            initialState: .init(animeId: 7),
            reducer: AnimeDetailReducer(
                detailClient: MockDetailClient(), reviewClient: reviews,
                communityClient: MockCommunityClient(),
                navigator: navigator, analytics: RecordingTracker(),
                setLastVisitedAnimeId: { _ in },
                shareAnime: { _, _ in }, openURL: { _ in }, reviewRefreshDelay: .milliseconds(10),
                toastDuration: .milliseconds(30)))
    }

    private func page(_ reviews: [RecentReview]?, lastId: Int?, lastValue: String? = nil)
        -> Result<AnimeReviewPage, TransportError>
    {
        return .success(AnimeReviewPage(reviews: reviews, lastId: lastId, lastValue: lastValue))
    }

    private func request(
        sort: String = "latest", spoiler: Bool = false, lastValue: String? = nil, lastId: Int? = nil
    )
        -> MockReviewClient.Action
    {
        return .animeReviews(
            animeId: 7, sort: sort, includesSpoiler: spoiler, lastValue: lastValue, lastId: lastId)
    }

    private var reviewRequests: [MockReviewClient.Action] {
        return reviews.actions.filter { if case .animeReviews = $0 { true } else { false } }
    }

    @Test("RT3. 처음에 리뷰(커서 없이)와 내 리뷰를 받는다. 스포일러를 끈 상태면 isSpoiler가 false인 리뷰만 보인다")
    func initialLoad() async {
        reviews.stubAnimeReviews(
            [
                page(
                    [.sample(1, isSpoiler: false), .sample(2, isSpoiler: true), .sample(3)],
                    lastId: 3, lastValue: "v")
            ],
            myReviews: [
                .success(
                    MyReview(reviewId: 9, rating: 4, content: "좋아요", createdAt: "d", likeCount: 2))
            ])
        let store = makeStore()

        await store.send(.appeared).finish()

        #expect(store.state.reviews.map(\.reviewId) == [1])
        #expect(store.state.reviewLastId == 3)
        #expect(store.state.reviewLastValue == "v")
        #expect(store.state.myReviewContent == "좋아요")
        #expect(store.state.storedRating == 4)
        #expect(store.state.myReviewId == 9)
        #expect(Set(reviews.actions) == [request(), .myReview(animeId: 7)])
    }

    @Test("RT4. 리뷰 탭이 보일 때마다 별점 상자를 저장된 별점으로 맞추고, 잠시 뒤 내 리뷰·리뷰를 다시 받는다")
    func tabRefresh() async {
        let store = makeStore()
        await store.send(.ratingDragged(3)).finish()

        let effect = store.send(.reviewTabAppeared)
        #expect(store.state.pendingRating == 0)
        await effect.finish()

        #expect(
            await waitUntil {
                reviewRequests.count == 1 && reviews.actions.contains(.myReview(animeId: 7))
            })
    }

    @Test("RT5. 마지막 리뷰가 보이면 커서로 이어 붙인다. 결과가 없으면 목록은 그대로, 커서는 비운다")
    func loadMore() async {
        reviews.stubAnimeReviews([
            page([.sample(1, isSpoiler: false)], lastId: 1, lastValue: "a"),
            page([.sample(2, isSpoiler: false)], lastId: 2),
            page(nil, lastId: nil),
        ])
        let store = makeStore()
        await store.send(.appeared).finish()

        await store.send(.reviewAppeared(.sample(1))).finish()
        await store.send(.reviewAppeared(.sample(2))).finish()

        #expect(store.state.reviews.map(\.reviewId) == [1, 2])
        #expect(store.state.reviewLastId == nil)
        #expect(
            reviewRequests == [request(), request(lastValue: "a", lastId: 1), request(lastId: 2)])
    }

    @Test("RT6. 스포일러를 켜면 거르지 않고 isSpoiler=true로 처음부터 다시 받는다")
    func spoilers() async {
        reviews.stubAnimeReviews([page([.sample(1, isSpoiler: true), .sample(2)], lastId: nil)])
        let store = makeStore()

        await store.send(.spoilerToggled).finish()

        #expect(store.state.reviews.map(\.reviewId) == [1, 2])
        #expect(reviewRequests == [request(spoiler: true)])
    }

    @Test(
        "RT7. 정렬: 버튼은 메뉴를 토글하고, 고르면 닫고 그 정렬로 처음부터",
        arguments: [
            (AnimeDetailReducer.ReviewSort.likes, "likes"), (.highRating, "ratingDesc"),
            (.lowRating, "ratingAsc"),
        ])
    func sort(sort: AnimeDetailReducer.ReviewSort, request: String) async {
        let store = makeStore()
        await store.send(.sortButtonTapped).finish()
        #expect(store.state.isSortMenuPresented)

        await store.send(.sortSelected(sort)).finish()

        #expect(!store.state.isSortMenuPresented)
        #expect(reviewRequests == [self.request(sort: request)])
    }

    @Test("RT8. 별점 상자를 끌 때마다: 리뷰가 없으면 별점 등록(성공하면 토스트), 있으면 별점 수정")
    func ratingDrag() async {
        let store = makeStore()

        await store.send(.ratingDragged(3.5)).finish()
        #expect(store.state.pendingRating == 3.5)
        #expect(await waitUntil { store.state.isRatingToastPresented })
        #expect(await waitUntil { !store.state.isRatingToastPresented })

        await store.send(
            .myReviewLoaded(
                MyReview(reviewId: 9, rating: 3.5, content: "", createdAt: nil, likeCount: nil))
        )
        .finish()
        await store.send(.ratingDragged(4)).finish()

        #expect(
            reviews.actions == [
                .registerRating(animeId: 7, rating: 3.5), .editRating(reviewId: 9, rating: 4),
            ])
    }

    @Test("RT9. 상세 리뷰 작성: 고른 별점을 저장하고 등록 요청 후 리뷰 작성으로 (내용 없이)")
    func writeDetail() async {
        let store = makeStore()
        await store.send(.ratingDragged(2.5)).finish()

        await store.send(.writeDetailTapped).finish()

        #expect(store.state.storedRating == 2.5)
        #expect(
            reviews.actions.filter { $0 == .registerRating(animeId: 7, rating: 2.5) }.count == 2)
        #expect(
            navigator.actions == [.push(ReviewRoute.write(animeId: 7, rating: 2.5, content: ""))])
    }

    @Test("RT10. 내 리뷰 카드의 별점은 표시만 바꾼다 (요청 없음)")
    func myRatingDrag() async {
        let store = makeStore()

        await store.send(.myRatingDragged(1.5)).finish()

        #expect(store.state.storedRating == 1.5)
        #expect(reviews.actions.isEmpty)
    }

    @Test("RT11. 내 리뷰 ⋮ 메뉴: 삭제는 지운 뒤 리뷰·내 리뷰를 다시 받는다(없다는 응답은 화면을 바꾸지 않음). 수정은 별점·내용으로 리뷰 작성")
    func myReviewMenu() async {
        reviews.stubAnimeReviews(
            [page([], lastId: nil)],
            myReviews: [
                .success(
                    MyReview(reviewId: 9, rating: 4, content: "c", createdAt: nil, likeCount: nil)),
                .success(nil),
            ])
        let store = makeStore()
        await store.send(.appeared).finish()

        await store.send(.myReviewMoreTapped(anchorMaxY: 300)).finish()
        #expect(store.state.isMyReviewMenuPresented)
        #expect(store.state.menuAnchorMaxY == 300)
        await store.send(.myReviewDeleteTapped).finish()
        #expect(!store.state.isMyReviewMenuPresented)
        #expect(
            await waitUntil { reviews.actions.filter { $0 == .myReview(animeId: 7) }.count == 2 })
        #expect(reviews.deletedIds == [9])
        #expect(store.state.myReviewContent == "c")

        await store.send(.myReviewMoreTapped(anchorMaxY: 300)).finish()
        await store.send(.myReviewEditTapped).finish()
        #expect(
            navigator.actions == [.push(ReviewRoute.write(animeId: 7, rating: 4, content: "c"))])
    }

    @Test("RT12. 리뷰 ⋮: 내 리뷰면 내 리뷰 메뉴, 아니면 신고/차단 메뉴(리뷰·사용자 기억). 스크롤하면 둘 다 닫는다")
    func reviewMore() async {
        let store = makeStore()

        await store.send(.reviewMoreTapped(.sample(4, isMine: true), anchorMaxY: 100)).finish()
        #expect(store.state.isMyReviewMenuPresented)
        await store.send(.reviewMoreTapped(.sample(5), anchorMaxY: 200)).finish()
        #expect(store.state.isBlockMenuPresented)
        #expect(store.state.selectedReviewId == 5)
        #expect(store.state.selectedUserId == 105)
        #expect(store.state.menuAnchorMaxY == 200)

        await store.send(.scrolled).finish()
        #expect(!store.state.isMyReviewMenuPresented)
        #expect(!store.state.isBlockMenuPresented)
    }

    @Test("RT13~RT15. 신고: 메뉴 → 확인 창(다음) → 사유 창 → 신고. 접수되면 토스트와 함께 처음부터 다시 받는다")
    func report() async {
        let store = makeStore()
        await store.send(.reviewMoreTapped(.sample(5), anchorMaxY: 0)).finish()

        await store.send(.reportMenuTapped).finish()
        #expect(!store.state.isBlockMenuPresented)
        #expect(store.state.isReportConfirmPresented)
        await store.send(.reportConfirmNextTapped).finish()
        #expect(!store.state.isReportConfirmPresented)
        #expect(store.state.isReportReasonPresented)
        await store.send(.reportReasonConfirmed("스팸")).finish()

        #expect(!store.state.isReportReasonPresented)
        #expect(reviews.actions.contains(.report(id: 5, message: "스팸")))
        #expect(await waitUntil { store.state.isReportToastPresented })
        #expect(await waitUntil { reviewRequests.count == 1 })
    }

    @Test("RT16·RT17. 차단: 메뉴 → 확인 → 차단. 성공하면 토스트와 다시 받기, 실패하면 아무것도. 취소는 닫기만")
    func block() async {
        let store = makeStore()
        await store.send(.reviewMoreTapped(.sample(5), anchorMaxY: 0)).finish()
        await store.send(.blockMenuTapped).finish()
        #expect(store.state.isBlockConfirmPresented)
        await store.send(.blockCancelled).finish()
        #expect(!store.state.isBlockConfirmPresented)

        reviews.stubRecent(action: .failure(.decoding))
        await store.send(.blockMenuTapped).finish()
        await store.send(.blockConfirmed).finish()
        #expect(!store.state.isBlockToastPresented)
        #expect(reviewRequests.isEmpty)

        reviews.stubRecent()
        await store.send(.blockMenuTapped).finish()
        await store.send(.blockConfirmed).finish()
        #expect(await waitUntil { store.state.isBlockToastPresented })
        #expect(reviews.actions.filter { $0 == .block(userId: 105) }.count == 2)
    }

    @Test("RT18. 리뷰 좋아요는 칸의 값으로 요청만 보낸다")
    func like() async {
        let store = makeStore()

        await store.send(.reviewLikeTapped(.sample(5), liked: true)).finish()
        await store.send(.reviewLikeTapped(.sample(5), liked: false)).finish()

        #expect(reviews.actions == [.like(id: 5, liked: true), .like(id: 5, liked: false)])
    }

    @Test("RT19. 화면을 떠나면 차단·신고 토스트를, 리뷰 탭을 떠나면 별점 토스트를 닫는다")
    func toastsOnLeave() async {
        let store = Store(
            initialState: AnimeDetailReducer.State(animeId: 7),
            reducer: AnimeDetailReducer(
                detailClient: MockDetailClient(), reviewClient: reviews,
                communityClient: MockCommunityClient(),
                navigator: navigator, analytics: RecordingTracker(),
                setLastVisitedAnimeId: { _ in },
                shareAnime: { _, _ in }, openURL: { _ in }, toastDuration: .seconds(30)))
        _ = store.send(.blocked)
        _ = store.send(.reported)
        _ = store.send(.ratingRegistered)

        _ = store.send(.disappeared)
        #expect(!store.state.isBlockToastPresented)
        #expect(!store.state.isReportToastPresented)
        #expect(store.state.isRatingToastPresented)
        _ = store.send(.reviewTabDisappeared)
        #expect(!store.state.isRatingToastPresented)
    }
}
