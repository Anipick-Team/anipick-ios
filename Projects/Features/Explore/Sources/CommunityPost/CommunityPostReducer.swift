import ClientCore
import CommunityClientInterface
import ExploreInterface
import MVICore
import Navigation

/// 커뮤니티 게시글 상세. 동작 목록: notes/2026-10-30-R-explore-05-community-post.md (PD1~PD22)
struct CommunityPostReducer: Reducer {
    let communityClient: any CommunityClient
    let navigator: any Navigator
    /// 공유 시트를 띄운다 (App: 게시글 Universal Link)
    let share: @MainActor (Int) -> Void
    var feedbackDuration: Duration = .milliseconds(1500)

    struct State: Equatable {
        let postId: Int
        var post: CommunityPostDetail?
        var comments: [CommunityComment] = []
        var commentsLastId: Int?
        var didStart = false
        /// 레거시는 화면을 만들 때 바로 받기 시작한다 — 첫 화면부터 "불러오는 중..."
        var isLoading = true
        var isLoadingMore = false
        var errorMessage: String?
        var isSubmittingComment = false
        var feedbackMessage: String?
        var currentImageIndex = 0
        var commentText = ""
        var replyTargetId: Int?
        var editingCommentId: Int?
        var isCommentFocused = false
        var isShowingPostActions = false
        var actionComment: CommunityComment?
        var isShowingCommentActions = false
        var isShowingReport = false
        var reportTarget = ReportTarget.post
        var reportTargetId = 0
        var isReportDropdownExpanded = false
        var selectedReportCategory: ReportCategory?

        init(postId: Int) {
            self.postId = postId
        }

        /// 받기 전·실패 시 보여 주는 빈 게시글 (레거시 `post` 기본값)
        var displayedPost: CommunityPostDetail {
            return post
                ?? CommunityPostDetail(
                    postId: postId, seriesId: 0, animeTitle: "애니메이션", authorName: "",
                    authorImageURL: nil,
                    date: "", isSpoiler: false, imageIds: [], imageURLs: [], title: "",
                    body: isLoading ? "불러오는 중..." : "게시글을 불러오지 못했습니다.", viewCount: 0, likeCount: 0,
                    commentCount: 0, isLiked: false, isMine: false)
        }

        var isCommentBlank: Bool {
            return commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var commentPlaceholder: String {
            if editingCommentId != nil {
                return "댓글을 수정해 주세요."
            }
            return replyTargetId == nil ? "댓글을 작성해 주세요." : "답글을 작성해 주세요."
        }
    }

    enum Intent: Sendable {
        case appeared
        case retryTapped
        case postUpdated(Int)
        case loaded(CommunityPostDetail, CommunityCommentPage)
        case loadFailed(String)
        case commentAppeared(CommunityComment)
        case moreCommentsLoaded(CommunityCommentPage?)
        case imageIndexChanged(Int)
        case postLikeTapped
        case postLikeFailed(isLiked: Bool, likeCount: Int)
        case commentLikeTapped(id: Int, isLiked: Bool)
        case commentLikeFailed(id: Int, isLiked: Bool)
        case shareTapped
        case backTapped
        case backgroundTapped
        case commentTextChanged(String)
        case commentFocusChanged(Bool)
        case submitTapped
        case commentSaved(String)
        case commentSaveFailed
        case replyTapped(commentId: Int)
        case replyCancelTapped
        case editCancelTapped
        case postMenuTapped
        case postActionsPresentedChanged(Bool)
        case editPostTapped
        case deletePostTapped
        case postDeleted
        case commentMenuTapped(CommunityComment)
        case commentActionsPresentedChanged(Bool)
        case editCommentTapped
        case deleteCommentTapped
        case commentDeleted
        case reportTapped(ReportTarget, id: Int)
        case reportDropdownTapped
        case reportCategorySelected(ReportCategory)
        case reportCloseTapped
        case reportSubmitTapped
        case reported
        case feedbackCleared
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 처음 한 번만 받는다 (레거시: ViewModel을 만들 때)
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            return fetch(&state)

        case .retryTapped:
            return fetch(&state)

        case .postUpdated(let postId):
            // 수정 화면에서 저장하고 돌아오면 다시 받는다
            guard postId == state.postId else {
                return .none
            }
            state.currentImageIndex = 0
            return fetch(&state)

        case .loaded(let post, let page):
            state.post = post
            state.comments = page.comments
            state.commentsLastId = page.lastId
            state.isLoading = false
            return .none

        case .loadFailed(let message):
            state.isLoading = false
            state.errorMessage = message
            return .none

        case .commentAppeared(let comment):
            guard comment.id == state.comments.last?.id, !state.isLoading, !state.isLoadingMore,
                let lastId = state.commentsLastId
            else {
                return .none
            }
            state.isLoadingMore = true
            let postId = state.postId
            return .run { [communityClient] in
                return .moreCommentsLoaded(
                    try? await communityClient.comments(postId: postId, lastId: lastId))
            }

        case .moreCommentsLoaded(let page):
            // 실패하면 커서를 그대로 두어 다시 시도할 수 있다
            if let page {
                state.comments += page.comments
                state.commentsLastId = page.lastId
            }
            state.isLoadingMore = false
            return .none

        case .imageIndexChanged(let index):
            state.currentImageIndex = index
            return .none

        case .postLikeTapped:
            guard let post = state.post else {
                return .none
            }
            let liked = !post.isLiked
            state.post?.isLiked = liked
            state.post?.likeCount = max(0, post.likeCount + (liked ? 1 : -1))
            let postId = state.postId
            return .run { [communityClient] in
                do {
                    try await communityClient.setPostLike(id: postId, liked: liked)
                    return nil
                } catch {
                    return .postLikeFailed(isLiked: post.isLiked, likeCount: post.likeCount)
                }
            }

        case .postLikeFailed(let isLiked, let likeCount):
            state.post?.isLiked = isLiked
            state.post?.likeCount = likeCount
            return .none

        case .commentLikeTapped(let id, let isLiked):
            Self.setCommentLike(&state.comments, id: id, isLiked: !isLiked)
            return .run { [communityClient] in
                do {
                    try await communityClient.setCommentLike(id: id, liked: !isLiked)
                    return nil
                } catch {
                    return .commentLikeFailed(id: id, isLiked: isLiked)
                }
            }

        case .commentLikeFailed(let id, let isLiked):
            Self.setCommentLike(&state.comments, id: id, isLiked: isLiked)
            return .none

        case .shareTapped:
            share(state.postId)
            return .none

        case .backTapped:
            state.isCommentFocused = false
            return pop()

        case .backgroundTapped:
            state.isCommentFocused = false
            return .none

        case .commentTextChanged(let text):
            state.commentText = text
            return .none

        case .commentFocusChanged(let isFocused):
            state.isCommentFocused = isFocused
            return .none

        case .submitTapped:
            let content = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else {
                return .none
            }
            let effect = saveComment(&state, content: content)
            // 등록 여부와 상관없이 입력을 비운다 (저장 중에 키보드로 보내면 글이 사라진다 — 레거시 그대로)
            state.commentText = ""
            state.replyTargetId = nil
            state.editingCommentId = nil
            state.isCommentFocused = false
            return effect

        case .commentSaved(let message):
            state.isSubmittingComment = false
            return .merge([showFeedback(&state, message), fetch(&state)])

        case .commentSaveFailed:
            state.isSubmittingComment = false
            return .none

        case .replyTapped(let commentId):
            state.replyTargetId = commentId
            state.isCommentFocused = true
            return .none

        case .replyCancelTapped:
            state.replyTargetId = nil
            state.isCommentFocused = false
            return .none

        case .editCancelTapped:
            state.editingCommentId = nil
            state.commentText = ""
            state.isCommentFocused = false
            return .none

        case .postMenuTapped:
            state.isCommentFocused = false
            state.isShowingPostActions = true
            return .none

        case .postActionsPresentedChanged(let isPresented):
            state.isShowingPostActions = isPresented
            return .none

        case .editPostTapped:
            let post = state.displayedPost
            guard post.seriesId != 0 else {
                return .none
            }
            return .run { [navigator] in
                await navigator.push(
                    ExploreRoute.communityEdit(
                        postId: post.postId, seriesId: post.seriesId, animeTitle: post.animeTitle,
                        title: post.title, content: post.body, isSpoiler: post.isSpoiler,
                        imageIds: post.imageIds))
                return nil
            }

        case .deletePostTapped:
            let postId = state.postId
            return .run { [communityClient] in
                return (try? await communityClient.deletePost(id: postId)) == nil
                    ? nil : .postDeleted
            }

        case .postDeleted:
            return .merge([showFeedback(&state, "게시글이 삭제되었습니다."), pop()])

        case .commentMenuTapped(let comment):
            state.actionComment = comment
            state.isCommentFocused = false
            state.isShowingCommentActions = true
            return .none

        case .commentActionsPresentedChanged(let isPresented):
            state.isShowingCommentActions = isPresented
            return .none

        case .editCommentTapped:
            guard let comment = state.actionComment else {
                return .none
            }
            state.editingCommentId = comment.id
            state.replyTargetId = nil
            state.commentText = comment.content
            state.isCommentFocused = true
            return .none

        case .deleteCommentTapped:
            guard let comment = state.actionComment else {
                return .none
            }
            return .run { [communityClient] in
                return (try? await communityClient.deleteComment(id: comment.id)) == nil
                    ? nil : .commentDeleted
            }

        case .commentDeleted:
            return .merge([showFeedback(&state, "댓글이 삭제되었습니다."), fetch(&state)])

        case .reportTapped(let target, let id):
            state.reportTarget = target
            state.reportTargetId = id
            state.selectedReportCategory = nil
            state.isReportDropdownExpanded = false
            state.isCommentFocused = false
            state.isShowingReport = true
            return .none

        case .reportDropdownTapped:
            state.isReportDropdownExpanded.toggle()
            return .none

        case .reportCategorySelected(let category):
            state.selectedReportCategory = category
            state.isReportDropdownExpanded = false
            return .none

        case .reportCloseTapped:
            state.isShowingReport = false
            return .none

        case .reportSubmitTapped:
            guard let category = state.selectedReportCategory else {
                return .none
            }
            state.isShowingReport = false
            let (target, targetId) = (state.reportTarget, state.reportTargetId)
            return .run { [communityClient] in
                return
                    (try? await communityClient.report(
                        target: target, targetId: targetId, category: category))
                    == nil ? nil : .reported
            }

        case .reported:
            return showFeedback(&state, "신고가 접수되었습니다.")

        case .feedbackCleared:
            state.feedbackMessage = nil
            return .none
        }
    }

    /// 레거시 `fetch()`: 상세와 첫 댓글 페이지를 함께 받는다 (받는 중이어도 다시 보낸다)
    private func fetch(_ state: inout State) -> Effect<Intent> {
        state.isLoading = true
        state.errorMessage = nil
        let postId = state.postId
        return .run { [communityClient] in
            do {
                async let detail = communityClient.postDetail(id: postId)
                async let comments = communityClient.comments(postId: postId, lastId: nil)
                let (post, page) = try await (detail, comments)
                return .loaded(post, page)
            } catch TransportError.decoding {
                return .loadFailed("게시글 상세 데이터가 없습니다.")
            } catch {
                return .loadFailed("게시글을 불러오지 못했습니다.")
            }
        }
    }

    /// 수정 중이면 수정, 아니면 (답글 대상이 있으면 답글로) 작성. 저장 중이면 보내지 않는다
    private func saveComment(_ state: inout State, content: String) -> Effect<Intent> {
        guard !state.isSubmittingComment else {
            return .none
        }
        state.isSubmittingComment = true
        let postId = state.postId
        if let commentId = state.editingCommentId {
            return .run { [communityClient] in
                do {
                    try await communityClient.updateComment(id: commentId, content: content)
                    return .commentSaved("댓글이 수정되었습니다.")
                } catch {
                    return .commentSaveFailed
                }
            }
        }
        let parentCommentId = state.replyTargetId
        return .run { [communityClient] in
            do {
                try await communityClient.createComment(
                    postId: postId, content: content, parentCommentId: parentCommentId)
                return .commentSaved(parentCommentId == nil ? "댓글이 등록되었습니다." : "답글이 등록되었습니다.")
            } catch {
                return .commentSaveFailed
            }
        }
    }

    /// 안내는 처음 뜬 뒤 1.5초에 지운다 (그사이 바뀐 문구도 함께 지운다 — 레거시 clearFeedback)
    private func showFeedback(_ state: inout State, _ message: String) -> Effect<Intent> {
        let wasHidden = state.feedbackMessage == nil
        state.feedbackMessage = message
        guard wasHidden else {
            return .none
        }
        return .run { [feedbackDuration] in
            try? await Task.sleep(for: feedbackDuration)
            return .feedbackCleared
        }
    }

    private func pop() -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.pop()
            return nil
        }
    }

    /// 댓글에서 먼저 찾고, 없으면 답글에서 찾는다. 상태가 바뀔 때만 개수를 ±1 (0 아래로는 내려가지 않음)
    static func setCommentLike(_ comments: inout [CommunityComment], id: Int, isLiked: Bool) {
        func apply(_ comment: inout CommunityComment) {
            let delta = comment.isLiked == isLiked ? 0 : (isLiked ? 1 : -1)
            comment.isLiked = isLiked
            comment.likeCount = max(0, comment.likeCount + delta)
        }
        if let index = comments.firstIndex(where: { $0.id == id }) {
            apply(&comments[index])
            return
        }
        for index in comments.indices {
            if let replyIndex = comments[index].replies.firstIndex(where: { $0.id == id }) {
                apply(&comments[index].replies[replyIndex])
                return
            }
        }
    }
}
