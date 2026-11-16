import DetailInterface
import MVICore
import Navigation
import ReviewClientInterface

/// 최근 리뷰 목록. 동작 목록: notes/2026-10-30-R-home-03-recent-reviews.md (RR4~RR16)
struct RecentReviewsReducer: Reducer {
    let reviewClient: any ReviewClient
    let navigator: any Navigator
    var toastDuration: Duration = .seconds(2)

    struct State: Equatable {
        var reviews: [RecentReview] = []
        var lastId: Int?
        var didStart = false
        var isLoading = false
        var isLoadingMore = false
        var hasMore = true
        /// 처음부터 다시 받을 때마다 올린다. 이전 세대의 응답은 버린다
        var generation = 0
        var pendingLikeIds: Set<Int> = []
        var isBlockMenuPresented = false
        /// ⋮ 버튼의 화면 위치 (메뉴를 그 위에 띄운다)
        var menuAnchorY: Double = 0
        var selectedReviewId = 0
        var selectedUserId = 0
        var isReportPopupPresented = false
        var isBlockPopupPresented = false
        var isReportToastPresented = false
        var isBlockToastPresented = false
    }

    enum Intent: Sendable {
        case appeared
        case reviewAppeared(RecentReview)
        case loaded(generation: Int, RecentReviewPage?)
        case moreLoaded(generation: Int, RecentReviewPage?)
        case likeTapped(RecentReview)
        case likeFinished(reviewId: Int, generation: Int, succeeded: Bool, previous: RecentReview)
        case reviewTapped(RecentReview)
        case moreButtonTapped(RecentReview, anchorY: Double)
        case scrolled
        case reportMenuTapped
        case blockMenuTapped
        case reportCancelled
        case reportConfirmed(reason: String)
        case reported
        case blockCancelled
        case blockConfirmed
        case blocked
        case reportToastExpired
        case blockToastExpired
        case disappeared
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 레거시는 ViewModel을 만들 때 한 번 받는다
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            return fetch(&state)

        case .reviewAppeared(let review):
            guard review.reviewId == state.reviews.last?.reviewId, !state.isLoading,
                !state.isLoadingMore,
                state.hasMore
            else {
                return .none
            }
            guard let lastId = state.lastId else {
                state.hasMore = false
                return .none
            }
            state.isLoadingMore = true
            let generation = state.generation
            return .run { [reviewClient] in
                return .moreLoaded(
                    generation: generation, try? await reviewClient.recentReviews(lastId: lastId))
            }

        case .loaded(let generation, let page):
            guard generation == state.generation else {
                return .none
            }
            state.isLoading = false
            if let page {
                state.reviews = page.reviews
                updateCursor(&state, page.lastId)
            }
            return .none

        case .moreLoaded(let generation, let page):
            guard generation == state.generation else {
                return .none
            }
            state.isLoadingMore = false
            if let page {
                state.reviews += page.reviews
                updateCursor(&state, page.lastId)
                if page.reviews.isEmpty {
                    state.hasMore = false
                }
            }
            return .none

        case .likeTapped(let review):
            // 좋아요 상태를 반대로. 요청 중인 리뷰는 무시한다
            let liked = !(review.isLiked ?? false)
            let reviewId = review.reviewId ?? 0
            guard !state.pendingLikeIds.contains(reviewId),
                let index = state.reviews.firstIndex(where: { $0.reviewId == reviewId }),
                (state.reviews[index].isLiked ?? false) != liked
            else {
                return .none
            }
            let previous = state.reviews[index]
            state.reviews[index].isLiked = liked
            state.reviews[index].likeCount = previous.likeCount.map {
                max(0, $0 + (liked ? 1 : -1))
            }
            state.pendingLikeIds.insert(reviewId)
            let generation = state.generation
            return .run { [reviewClient] in
                let succeeded =
                    (try? await reviewClient.setReviewLike(id: reviewId, liked: liked)) ?? false
                return .likeFinished(
                    reviewId: reviewId, generation: generation, succeeded: succeeded,
                    previous: previous)
            }

        case .likeFinished(let reviewId, let generation, let succeeded, let previous):
            state.pendingLikeIds.remove(reviewId)
            guard !succeeded, generation == state.generation,
                let index = state.reviews.firstIndex(where: { $0.reviewId == reviewId })
            else {
                return .none
            }
            state.reviews[index].isLiked = previous.isLiked
            state.reviews[index].likeCount = previous.likeCount
            return .none

        case .reviewTapped(let review):
            return .run { [navigator] in
                await navigator.push(DetailRoute.anime(id: review.animeId ?? 0))
                return nil
            }

        case .moreButtonTapped(let review, let anchorY):
            state.isBlockMenuPresented.toggle()
            state.selectedReviewId = review.reviewId ?? 0
            state.menuAnchorY = anchorY
            state.selectedUserId = review.userId ?? 0
            return .none

        case .scrolled:
            state.isBlockMenuPresented = false
            return .none

        case .reportMenuTapped:
            state.isBlockMenuPresented = false
            state.isReportPopupPresented = true
            return .none

        case .blockMenuTapped:
            // 레거시: 차단 확인 창을 띄우면서 곧바로 처음부터 다시 받는다
            state.isBlockMenuPresented = false
            state.isBlockPopupPresented.toggle()
            return fetch(&state)

        case .reportCancelled:
            state.isReportPopupPresented = false
            return fetch(&state)

        case .reportConfirmed(let reason):
            let reviewId = state.selectedReviewId
            state.isReportPopupPresented = false
            let report: Effect<Intent> = .run { [reviewClient] in
                return (try? await reviewClient.reportReview(id: reviewId, message: reason)) == nil
                    ? nil : .reported
            }
            return .merge([report, fetch(&state)])

        case .reported:
            return toggleToast(&state.isReportToastPresented, expired: .reportToastExpired)

        case .blockCancelled:
            state.isBlockPopupPresented = false
            return .none

        case .blockConfirmed:
            let userId = state.selectedUserId
            state.isBlockPopupPresented = false
            let block: Effect<Intent> = .run { [reviewClient] in
                return (try? await reviewClient.blockUser(id: userId)) == nil ? nil : .blocked
            }
            return .merge([block, fetch(&state)])

        case .blocked:
            return toggleToast(&state.isBlockToastPresented, expired: .blockToastExpired)

        case .reportToastExpired:
            state.isReportToastPresented = false
            return .none

        case .blockToastExpired:
            state.isBlockToastPresented = false
            return .none

        case .disappeared:
            state.isBlockToastPresented = false
            state.isReportToastPresented = false
            return .none

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 레거시 `fetchRecentReview`: 세대를 올리고 커서 없이 받아 목록을 바꾼다
    private func fetch(_ state: inout State) -> Effect<Intent> {
        state.generation += 1
        state.lastId = nil
        state.hasMore = true
        state.isLoading = true
        state.isLoadingMore = false
        let generation = state.generation
        return .run { [reviewClient] in
            return .loaded(
                generation: generation, try? await reviewClient.recentReviews(lastId: nil))
        }
    }

    private func updateCursor(_ state: inout State, _ lastId: Int?) {
        state.lastId = lastId
        if lastId == nil {
            state.hasMore = false
        }
    }

    /// 레거시 PopupView 토스트: 토글로 띄우고(이미 떠 있으면 닫힘) 2초 뒤 닫는다
    private func toggleToast(_ isPresented: inout Bool, expired: Intent) -> Effect<Intent> {
        isPresented.toggle()
        guard isPresented else {
            return .none
        }
        return .run { [toastDuration] in
            try? await Task.sleep(for: toastDuration)
            return expired
        }
    }
}
