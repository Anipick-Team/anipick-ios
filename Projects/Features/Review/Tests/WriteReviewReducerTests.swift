import Analytics
import ClientCore
import FeatureTestSupport
import Foundation
import MVICore
import ReviewClientTesting
import Testing
import os

@testable import ReviewFeature

/// 동작 목록 V1~V10 (notes/2026-10-29-R-review-01-write-review.md)과 1:1
@Suite("리뷰 작성", .timeLimit(.minutes(1)))
struct WriteReviewReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()
    private let openedURLs = OSAllocatedUnfairLock(initialState: [URL]())
    private let writtenCount = OSAllocatedUnfairLock(initialState: 0)

    private func makeReducer(_ client: MockReviewClient) -> WriteReviewReducer {
        return WriteReviewReducer(
            reviewClient: client,
            navigator: navigator,
            analytics: tracker,
            openURL: { [openedURLs] url in openedURLs.withLock { $0.append(url) } },
            onReviewWritten: { [writtenCount] in writtenCount.withLock { $0 += 1 } }
        )
    }

    private func makeStore(
        _ client: MockReviewClient = MockReviewClient(),
        content: String = ""
    ) -> Store<WriteReviewReducer> {
        return Store(
            initialState: WriteReviewReducer.State(animeId: 7, rating: 3.5, content: content),
            reducer: makeReducer(client)
        )
    }

    @Test("V1. 처음 내용이 비어 있으면 작성, 있으면 수정 화면이다")
    func titles() {
        let new = WriteReviewReducer.State(animeId: 1, rating: 0, content: "")
        let edit = WriteReviewReducer.State(animeId: 1, rating: 0, content: "기존")

        #expect(new.title == "리뷰 작성")
        #expect(new.submitTitle == "리뷰 작성하기")
        #expect(edit.title == "리뷰 수정")
        #expect(edit.submitTitle == "리뷰 수정하기")
    }

    @Test("V2. 받은 별점으로 시작하고 끈 값으로 바뀐다")
    func rating() async {
        let store = makeStore()
        #expect(store.state.rating == 3.5)

        await store.send(.ratingChanged(4.5)).finish()

        #expect(store.state.rating == 4.5)
    }

    @Test("V3. 수정이어도 스포일러는 꺼진 채로 시작한다 (레거시 보존)")
    func spoilerStartsOff() {
        #expect(makeStore(content: "기존 리뷰").state.isSpoiler == false)
    }

    @Test("V4. 스포일러를 누를 때마다 켜고 끈다")
    func togglesSpoiler() async {
        let store = makeStore()

        await store.send(.spoilerTapped).finish()
        #expect(store.state.isSpoiler)
        await store.send(.spoilerTapped).finish()
        #expect(store.state.isSpoiler == false)
    }

    @Test("V5. 내용과 글자 수 표시가 함께 바뀐다")
    func content() async {
        let store = makeStore(content: "기존")
        #expect(store.state.counterText == "2/200")

        await store.send(.contentChanged("새 리뷰 내용")).finish()

        #expect(store.state.content == "새 리뷰 내용")
        #expect(store.state.counterText == "7/200")
    }

    @Test("V6. 뒤로 버튼은 한 화면 뒤로 가고 저장하지 않는다")
    func goesBack() async {
        let client = MockReviewClient()
        let store = makeStore(client)

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
        #expect(client.written.isEmpty)
    }

    @Test("V7. 가이드라인 전체보기는 커뮤니티 가이드라인을 외부로 연다")
    func opensGuideline() async {
        await makeStore().send(.guidelineTapped).finish()

        #expect(
            openedURLs.withLock { $0 }
                == [URL(string: "https://anipick.p-e.kr/community-guidelines.html")!])
    }

    @Test("V8. 작성하기는 지금 값으로 저장을 보내고 응답을 기다리지 않고 닫는다")
    func submitsWithoutWaiting() async {
        let client = MockReviewClient(delay: .seconds(1))
        let store = makeStore(client)
        await store.send(.ratingChanged(4)).finish()
        await store.send(.spoilerTapped).finish()
        await store.send(.contentChanged("재밌다")).finish()
        let start = ContinuousClock.now

        await store.send(.submitTapped).finish()

        #expect(ContinuousClock.now - start < .milliseconds(500))
        #expect(navigator.actions == [.pop])
        #expect(await waitUntil { !client.written.isEmpty })
        #expect(
            client.written
                == [.init(animeId: 7, content: "재밌다", rating: 4, isSpoiler: true)])
    }

    @Test("V9. 저장되면 화면이 닫힌 뒤에도 review_write 이벤트를 보내고 별점 목록에 알린다")
    func recordsAfterScreenCloses() async {
        let client = MockReviewClient(delay: .milliseconds(200))
        var store: Store<WriteReviewReducer>? = makeStore(client)
        await store?.send(.submitTapped).finish()

        store = nil

        #expect(await waitUntil { writtenCount.withLock { $0 } == 1 })
        #expect(tracker.events == [.reviewWrite(animeId: 7, rating: 3.5, isSpoiler: false)])
        #expect(tracker.nonFatals.isEmpty)
    }

    @Test("V10. 저장에 실패하면 patchReview 오류를 기록하고 알리지 않는다")
    func recordsFailure() async {
        let client = MockReviewClient(result: .failure(.offline))

        await makeStore(client).send(.submitTapped).finish()

        #expect(await waitUntil { !tracker.nonFatals.isEmpty })
        #expect(tracker.nonFatals.first?.breadcrumb.hasPrefix("[patchReview] ") == true)
        #expect(tracker.events.first?.name == "api_error")
        #expect(writtenCount.withLock { $0 } == 0)
    }
}
