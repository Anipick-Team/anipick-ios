import ClientCore
import CommunityClientInterface
import CommunityClientTesting
import ExploreInterface
import FeatureTestSupport
import MVICore
import Testing
import os

@testable import ExploreFeature

/// 동작 목록 PD1~PD14 (notes/2026-10-30-R-explore-05-community-post.md)과 1:1
@Suite("커뮤니티 게시글 상세", .timeLimit(.minutes(1)))
struct CommunityPostReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockCommunityClient()
    private let shared = OSAllocatedUnfairLock<[Int]>(initialState: [])

    private func makeStore(postId: Int = 3) -> Store<CommunityPostReducer> {
        return Store(
            initialState: CommunityPostReducer.State(postId: postId),
            reducer: CommunityPostReducer(
                communityClient: client, navigator: navigator,
                share: { [shared] id in shared.withLock { $0.append(id) } },
                feedbackDuration: .milliseconds(20)))
    }

    /// 상세와 첫 댓글을 받은 Store
    private func loadedStore(
        _ post: CommunityPostDetail = .sample(3), comments: [CommunityComment] = [.sample(10)],
        lastId: Int? = nil
    ) async -> Store<CommunityPostReducer> {
        client.stubDetail(
            [.success(post)],
            comments: [.success(CommunityCommentPage(comments: comments, lastId: lastId))])
        let store = makeStore()
        await store.send(.appeared).finish()
        return store
    }

    @Test("PD1. 처음 보일 때 한 번만 상세와 첫 댓글을 함께 받는다. 받기 전 본문은 \"불러오는 중...\"")
    func loadsOnce() async {
        let store = makeStore()
        #expect(store.state.displayedPost.body == "불러오는 중...")
        client.stubDetail(
            [.success(.sample(3))],
            comments: [.success(CommunityCommentPage(comments: [.sample(1)], lastId: 1))])

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(Set(client.detailRequests) == [.detail(3), .comments(postId: 3, lastId: nil)])
        #expect(client.detailRequests.count == 2)
        #expect(store.state.post == .sample(3))
        #expect(store.state.comments == [.sample(1)])
        #expect(store.state.commentsLastId == 1)
        #expect(!store.state.isLoading)
    }

    @Test(
        "PD1. 실패: 상세 결과가 없으면 \"게시글 상세 데이터가 없습니다.\", 그 밖은 \"게시글을 불러오지 못했습니다.\". 다시 시도는 다시 받는다",
        arguments: [
            (TransportError.decoding, "게시글 상세 데이터가 없습니다."), (.offline, "게시글을 불러오지 못했습니다."),
            (.server(status: 500), "게시글을 불러오지 못했습니다."),
        ])
    func failure(error: TransportError, message: String) async {
        client.stubDetail([.failure(error), .success(.sample(3))])
        let store = makeStore()

        await store.send(.appeared).finish()
        #expect(store.state.errorMessage == message)
        #expect(store.state.displayedPost.body == "게시글을 불러오지 못했습니다.")

        let retry = store.send(.retryTapped)
        #expect(store.state.errorMessage == nil)
        await retry.finish()
        #expect(store.state.post == .sample(3))
    }

    @Test("PD2. 같은 글의 수정 알림이면 사진 위치를 처음으로 돌리고 다시 받는다. 다른 글이면 무시")
    func postUpdated() async {
        let store = await loadedStore(.sample(3, imageIds: [1, 2]))
        await store.send(.imageIndexChanged(1)).finish()

        await store.send(.postUpdated(9)).finish()
        #expect(store.state.currentImageIndex == 1)
        await store.send(.postUpdated(3)).finish()

        #expect(store.state.currentImageIndex == 0)
        #expect(client.detailRequests.filter { $0 == .detail(3) }.count == 2)
    }

    @Test("PD3. 마지막 댓글이 보이면 커서로 이어 받는다. 커서가 없거나 받는 중이면 받지 않고, 실패하면 그대로")
    func loadsMoreComments() async {
        let store = await loadedStore(comments: [.sample(10), .sample(11)], lastId: 11)
        client.stubDetail(
            [.success(.sample(3))],
            comments: [
                .failure(.offline),
                .success(CommunityCommentPage(comments: [.sample(12)], lastId: nil)),
            ])

        await store.send(.commentAppeared(.sample(10))).finish()
        await store.send(.commentAppeared(.sample(11))).finish()
        #expect(store.state.comments.map(\.id) == [10, 11])
        #expect(!store.state.isLoadingMore)
        await store.send(.commentAppeared(.sample(11))).finish()
        await store.send(.commentAppeared(.sample(12))).finish()

        #expect(store.state.comments.map(\.id) == [10, 11, 12])
        #expect(
            client.detailRequests.suffix(2) == [
                .comments(postId: 3, lastId: 11), .comments(postId: 3, lastId: 11),
            ])
    }

    @Test("PD4. 게시글 좋아요는 먼저 바꾸고 요청한다. 실패하면 되돌린다")
    func postLike() async {
        let store = await loadedStore(.sample(3, isLiked: false, likeCount: 0))

        await store.send(.postLikeTapped).finish()
        #expect(store.state.post?.isLiked == true)
        #expect(store.state.post?.likeCount == 1)

        client.stubDetail(actionFailure: .offline)
        let unlike = store.send(.postLikeTapped)
        #expect(store.state.post?.isLiked == false)
        #expect(store.state.post?.likeCount == 0)
        await unlike.finish()

        #expect(store.state.post?.isLiked == true)
        #expect(store.state.post?.likeCount == 1)
        #expect(
            client.detailRequests.suffix(2) == [
                .postLike(id: 3, liked: true), .postLike(id: 3, liked: false),
            ])
    }

    @Test("PD5. 댓글·답글 좋아요: 같은 엔드포인트, 실패하면 되돌린다. 개수는 0 아래로 내려가지 않는다")
    func commentLike() async {
        let store = await loadedStore(
            comments: [
                .sample(
                    10, isLiked: false, likeCount: 0,
                    replies: [.sample(20, isLiked: true, likeCount: 0)])
            ])

        await store.send(.commentLikeTapped(id: 10, isLiked: false)).finish()
        await store.send(.commentLikeTapped(id: 20, isLiked: true)).finish()
        #expect(store.state.comments[0].isLiked)
        #expect(store.state.comments[0].likeCount == 1)
        #expect(!store.state.comments[0].replies[0].isLiked)
        #expect(store.state.comments[0].replies[0].likeCount == 0)

        client.stubDetail(actionFailure: .offline)
        await store.send(.commentLikeTapped(id: 10, isLiked: true)).finish()

        #expect(store.state.comments[0].isLiked)
        #expect(store.state.comments[0].likeCount == 1)
        #expect(
            client.detailRequests.suffix(3)
                == [
                    .commentLike(id: 10, liked: true), .commentLike(id: 20, liked: false),
                    .commentLike(id: 10, liked: false),
                ])
    }

    @Test("PD6·PD7. 공유는 App에 글 id를 넘긴다. 뒤로는 키보드를 내리고 pop")
    func shareAndBack() async {
        let store = makeStore()
        await store.send(.commentFocusChanged(true)).finish()

        await store.send(.shareTapped).finish()
        await store.send(.backTapped).finish()

        #expect(shared.withLock { $0 } == [3])
        #expect(!store.state.isCommentFocused)
        #expect(navigator.actions == [.pop])
    }

    @Test("PD8. 댓글 등록: 앞뒤 공백을 지워 보내고 입력을 비운다. 성공하면 안내 후 다시 받는다. 빈 입력은 무시")
    func createComment() async {
        let store = await loadedStore()
        await store.send(.commentTextChanged("   ")).finish()
        await store.send(.submitTapped).finish()
        #expect(store.state.commentText == "   ")

        await store.send(.commentTextChanged(" 안녕 ")).finish()
        await store.send(.submitTapped).finish()

        #expect(store.state.commentText == "")
        #expect(store.state.feedbackMessage == "댓글이 등록되었습니다.")
        #expect(
            client.detailRequests.contains(
                .createComment(postId: 3, content: "안녕", parentCommentId: nil)))
        #expect(await waitUntil { client.detailRequests.filter { $0 == .detail(3) }.count == 2 })
        #expect(await waitUntil { store.state.feedbackMessage == nil })
    }

    @Test("PD8·PD9. 답글: 댓글의 \"댓글\" 버튼으로 대상을 정하고 보낸다. 취소하면 대상만 지운다")
    func reply() async {
        let store = await loadedStore()
        await store.send(.replyTapped(commentId: 10)).finish()
        #expect(store.state.isCommentFocused)
        #expect(store.state.commentPlaceholder == "답글을 작성해 주세요.")
        await store.send(.commentTextChanged("답")).finish()
        await store.send(.replyCancelTapped).finish()
        #expect(store.state.replyTargetId == nil)
        #expect(store.state.commentText == "답")

        await store.send(.replyTapped(commentId: 10)).finish()
        await store.send(.submitTapped).finish()

        #expect(
            client.detailRequests.contains(
                .createComment(postId: 3, content: "답", parentCommentId: 10)))
        #expect(store.state.feedbackMessage == "답글이 등록되었습니다.")
        #expect(store.state.replyTargetId == nil)
    }

    @Test("PD8·PD11. 댓글 수정: 메뉴의 수정으로 내용을 채우고 PATCH. 수정 취소는 입력까지 비운다")
    func editComment() async {
        let store = await loadedStore(comments: [.sample(10, isMine: true)])
        await store.send(.replyTapped(commentId: 10)).finish()
        await store.send(.commentMenuTapped(.sample(10, isMine: true))).finish()
        #expect(store.state.isShowingCommentActions)
        #expect(!store.state.isCommentFocused)

        await store.send(.editCommentTapped).finish()
        #expect(store.state.commentText == "댓글 10")
        #expect(store.state.replyTargetId == nil)
        #expect(store.state.commentPlaceholder == "댓글을 수정해 주세요.")
        await store.send(.editCancelTapped).finish()
        #expect(store.state.commentText == "")

        await store.send(.editCommentTapped).finish()
        await store.send(.commentTextChanged("고침")).finish()
        await store.send(.submitTapped).finish()

        #expect(client.detailRequests.contains(.updateComment(id: 10, content: "고침")))
        #expect(store.state.feedbackMessage == "댓글이 수정되었습니다.")
    }

    @Test("PD8. 저장 중에 다시 보내면 요청하지 않지만 입력은 비운다. 실패하면 저장 중만 푼다")
    func submittingAndFailure() async {
        let store = await loadedStore()
        client.stubDetail([.success(.sample(3))], actionFailure: .offline)
        await store.send(.commentTextChanged("하나")).finish()
        let first = store.send(.submitTapped)
        #expect(store.state.isSubmittingComment)
        await store.send(.commentTextChanged("둘")).finish()
        await store.send(.submitTapped).finish()
        #expect(store.state.commentText == "")
        await first.finish()

        #expect(!store.state.isSubmittingComment)
        #expect(store.state.feedbackMessage == nil)
        #expect(
            client.detailRequests.filter { if case .createComment = $0 { true } else { false } }
                .count == 1)
    }

    @Test("PD10. 게시글 메뉴: 내 글은 수정(시리즈 id가 있을 때만)·삭제(성공하면 안내 후 pop)")
    func postMenu() async {
        let store = await loadedStore(.sample(3, seriesId: 7, isMine: true, imageIds: [4]))
        await store.send(.postMenuTapped).finish()
        #expect(store.state.isShowingPostActions)

        await store.send(.editPostTapped).finish()
        await store.send(.deletePostTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(
                        ExploreRoute.communityEdit(
                            postId: 3, seriesId: 7, animeTitle: "애니", title: "제목 3",
                            content: "본문 3",
                            isSpoiler: false, imageIds: [4])), .pop,
                ])
        #expect(store.state.feedbackMessage == "게시글이 삭제되었습니다.")

        let noSeries = await loadedStore(.sample(3, seriesId: 0, isMine: true))
        client.stubDetail(actionFailure: .offline)
        await noSeries.send(.editPostTapped).finish()
        await noSeries.send(.deletePostTapped).finish()
        #expect(navigator.actions.count == 2)
    }

    @Test("PD11. 댓글 삭제: 성공하면 안내 후 다시 받고, 실패하면 아무것도 하지 않는다")
    func deleteComment() async {
        let store = await loadedStore(comments: [.sample(10, isMine: true)])
        await store.send(.commentMenuTapped(.sample(10, isMine: true))).finish()

        await store.send(.deleteCommentTapped).finish()

        #expect(store.state.feedbackMessage == "댓글이 삭제되었습니다.")
        #expect(await waitUntil { client.detailRequests.filter { $0 == .detail(3) }.count == 2 })
    }

    @Test("PD12. 신고: 유형을 골라야 보낸다. 보내면 창을 닫고, 접수되면 안내한다 (실패는 안내 없음)")
    func report() async {
        let store = await loadedStore()
        await store.send(.reportTapped(.comment, id: 10)).finish()
        #expect(store.state.isShowingReport)
        await store.send(.reportSubmitTapped).finish()
        #expect(store.state.isShowingReport)

        await store.send(.reportDropdownTapped).finish()
        #expect(store.state.isReportDropdownExpanded)
        await store.send(.reportCategorySelected(.spam)).finish()
        #expect(!store.state.isReportDropdownExpanded)
        await store.send(.reportSubmitTapped).finish()

        #expect(!store.state.isShowingReport)
        #expect(client.detailRequests.last == .report(.comment, targetId: 10, .spam))
        #expect(store.state.feedbackMessage == "신고가 접수되었습니다.")

        #expect(await waitUntil { store.state.feedbackMessage == nil })
        client.stubDetail(actionFailure: .offline)
        await store.send(.reportTapped(.post, id: 3)).finish()
        #expect(store.state.selectedReportCategory == nil)
        await store.send(.reportCategorySelected(.etc)).finish()
        await store.send(.reportSubmitTapped).finish()
        #expect(store.state.feedbackMessage == nil)
    }

    @Test("PD13. 안내는 처음 뜬 뒤 정해진 시간에 사라진다 (그사이 바뀐 문구도 함께)")
    func feedbackClears() async {
        let store = await loadedStore(comments: [.sample(10, isMine: true)])
        await store.send(.commentMenuTapped(.sample(10, isMine: true))).finish()
        await store.send(.deleteCommentTapped).finish()
        await store.send(.reportTapped(.comment, id: 10)).finish()
        await store.send(.reportCategorySelected(.abuse)).finish()
        await store.send(.reportSubmitTapped).finish()
        #expect(store.state.feedbackMessage == "신고가 접수되었습니다.")

        #expect(await waitUntil { store.state.feedbackMessage == nil })
    }
}
