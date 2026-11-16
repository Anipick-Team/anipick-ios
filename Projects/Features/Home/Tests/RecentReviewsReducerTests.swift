import ClientCore
import DetailInterface
import FeatureTestSupport
import MVICore
import ReviewClientInterface
import ReviewClientTesting
import Testing

@testable import HomeFeature

/// 동작 목록 RR4~RR15 (notes/2026-10-30-R-home-03-recent-reviews.md)과 1:1
@Suite("최근 리뷰", .timeLimit(.minutes(1)))
struct RecentReviewsReducerTests {
    private let navigator = RecordingNavigator()

    private func page(_ ids: [Int], lastId: Int?) -> Result<RecentReviewPage?, TransportError> {
        return .success(RecentReviewPage(reviews: ids.map { .sample($0) }, lastId: lastId))
    }

    private func makeStore(_ client: MockReviewClient) -> Store<RecentReviewsReducer> {
        return Store(
            initialState: .init(),
            reducer: RecentReviewsReducer(
                reviewClient: client, navigator: navigator, toastDuration: .milliseconds(20)))
    }

    @Test("RR4. 처음 보일 때 한 번만 커서 없이 받는다")
    func loadsOnce() async {
        let client = MockReviewClient()
        client.stubRecent([page([1, 2], lastId: 2)])
        let store = makeStore(client)

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.reviews.map(\.reviewId) == [1, 2])
        #expect(client.actions == [.recent(lastId: nil)])
        #expect(!store.state.isLoading)
    }

    @Test("RR5. 마지막 리뷰가 보이면 커서로 이어 받는다. 커서가 없거나 빈 페이지면 끝, 받는 중이면 받지 않는다")
    func loadsMore() async {
        let client = MockReviewClient()
        client.stubRecent([page([1, 2], lastId: 2), page([3], lastId: 3), page([], lastId: 4)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.reviewAppeared(.sample(1))).finish()
        await store.send(.reviewAppeared(.sample(2))).finish()
        await store.send(.reviewAppeared(.sample(3))).finish()
        #expect(store.state.reviews.map(\.reviewId) == [1, 2, 3])
        #expect(!store.state.hasMore)
        await store.send(.reviewAppeared(.sample(3))).finish()

        #expect(client.actions == [.recent(lastId: nil), .recent(lastId: 2), .recent(lastId: 3)])
    }

    @Test("RR6. 처음부터 다시 받으면 진행 중이던 이어 받기 응답은 버린다")
    func dropsOldGeneration() async {
        let client = MockReviewClient()
        client.stubRecent([page([1], lastId: 1)])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        await store.send(.reportCancelled).finish()
        await store.send(
            .moreLoaded(generation: 1, RecentReviewPage(reviews: [.sample(9)], lastId: 9))
        ).finish()
        await store.send(.loaded(generation: 1, RecentReviewPage(reviews: [.sample(8)], lastId: 8)))
            .finish()

        #expect(store.state.reviews.map(\.reviewId) == [1])
        #expect(store.state.generation == 2)
    }

    @Test("RR7. 좋아요는 먼저 바꾸고(개수 ±1, 없으면 그대로) 요청한다. 실패나 code≠200이면 되돌린다. 요청 중에는 다시 누를 수 없다")
    func like() async {
        let client = MockReviewClient(delay: .milliseconds(30))
        client.stubRecent([
            .success(
                RecentReviewPage(
                    reviews: [.sample(1, likeCount: 0), .sample(2, likeCount: nil)], lastId: nil))
        ])
        let store = makeStore(client)
        await store.send(.appeared).finish()

        let first = store.send(.likeTapped(.sample(1, likeCount: 0)))
        #expect(store.state.reviews[0].isLiked == true)
        #expect(store.state.reviews[0].likeCount == 1)
        await store.send(.likeTapped(store.state.reviews[0])).finish()
        await first.finish()
        #expect(store.state.reviews[0].isLiked == true)

        client.stubRecent(like: .success(false))
        await store.send(.likeTapped(store.state.reviews[1])).finish()
        #expect(store.state.reviews[1].isLiked == false)
        #expect(store.state.reviews[1].likeCount == nil)

        #expect(client.actions.suffix(2) == [.like(id: 1, liked: true), .like(id: 2, liked: true)])
    }

    @Test("RR8. 리뷰를 누르면 그 애니 상세로(id가 없으면 0), 뒤로는 pop")
    func navigation() async {
        let store = makeStore(MockReviewClient())

        await store.send(.reviewTapped(.sample(3))).finish()
        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.push(DetailRoute.anime(id: 13)), .pop])
    }

    @Test("RR9. ⋮ 버튼은 메뉴를 토글하고 대상 리뷰·사용자를 기억한다. 스크롤하면 메뉴를 닫는다")
    func menu() async {
        let store = makeStore(MockReviewClient())

        await store.send(.moreButtonTapped(.sample(4), anchorY: 300)).finish()
        #expect(store.state.isBlockMenuPresented)
        #expect(store.state.selectedReviewId == 4)
        #expect(store.state.selectedUserId == 104)
        #expect(store.state.menuAnchorY == 300)
        await store.send(.scrolled).finish()

        #expect(!store.state.isBlockMenuPresented)
    }

    @Test("RR10·RR11. 신고: 메뉴 → 사유 창. 확인하면 사유 문구로 신고하고 처음부터 다시 받는다. 접수되면 토스트, 취소해도 다시 받는다")
    func report() async {
        let client = MockReviewClient()
        let store = makeStore(client)
        await store.send(.moreButtonTapped(.sample(4), anchorY: 0)).finish()
        await store.send(.reportMenuTapped).finish()
        #expect(!store.state.isBlockMenuPresented)
        #expect(store.state.isReportPopupPresented)

        await store.send(.reportConfirmed(reason: "개인정보 노출")).finish()

        #expect(!store.state.isReportPopupPresented)
        #expect(client.actions.contains(.report(id: 4, message: "개인정보 노출")))
        #expect(client.actions.contains(.recent(lastId: nil)))
        #expect(await waitUntil { store.state.isReportToastPresented })
        #expect(await waitUntil { !store.state.isReportToastPresented })

        await store.send(.reportCancelled).finish()
        #expect(client.actions.filter { $0 == .recent(lastId: nil) }.count == 2)
    }

    @Test("RR12·RR13. 차단: 메뉴에서 누르면 확인 창을 띄우며 바로 다시 받는다. 확인하면 차단하고 다시 받는다. 실패하면 토스트 없음")
    func block() async {
        let client = MockReviewClient()
        let store = makeStore(client)
        await store.send(.moreButtonTapped(.sample(4), anchorY: 0)).finish()

        await store.send(.blockMenuTapped).finish()
        #expect(store.state.isBlockPopupPresented)
        #expect(client.actions == [.recent(lastId: nil)])

        await store.send(.blockConfirmed).finish()
        #expect(client.actions.contains(.block(userId: 104)))
        #expect(await waitUntil { store.state.isBlockToastPresented })

        client.stubRecent(action: .failure(.offline))
        await store.send(.blockMenuTapped).finish()
        await store.send(.blockCancelled).finish()
        #expect(!store.state.isBlockPopupPresented)
    }

    @Test("RR14. 토스트는 토글이다 (떠 있는 동안 다시 접수되면 닫힌다). 화면을 떠나면 닫는다")
    func toasts() async {
        let store = Store(
            initialState: RecentReviewsReducer.State(),
            reducer: RecentReviewsReducer(
                reviewClient: MockReviewClient(), navigator: navigator,
                toastDuration: .milliseconds(300)))

        let first = store.send(.reported)
        #expect(store.state.isReportToastPresented)
        await store.send(.reported).finish()
        #expect(!store.state.isReportToastPresented)
        _ = first

        await store.send(.blocked).finish()
        await store.send(.disappeared).finish()
        #expect(!store.state.isBlockToastPresented)
    }

    @Test("RR15. 실패하면 받는 중만 끝낸다")
    func failure() async {
        let client = MockReviewClient()
        client.stubRecent([.failure(.offline)])
        let store = makeStore(client)

        await store.send(.appeared).finish()

        #expect(!store.state.isLoading)
        #expect(store.state.reviews.isEmpty)
    }
}
