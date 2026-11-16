import DetailInterface
import MVICore
import MyInfoClientInterface
import Navigation
import ReviewClientInterface
import ReviewInterface

/// 평가한 작품. 동작 목록: notes/2026-10-29-R-myinfo-02-rated.md (RA1~RA14)
struct RatedReviewsReducer: Reducer {
    let myInfoClient: any MyInfoClient
    let reviewClient: any ReviewClient
    let navigator: any Navigator
    /// 삭제 완료 안내가 사라질 때까지 (레거시 2초)
    var toastDuration: Duration = .seconds(2)

    struct State: Equatable {
        var reviews: [RatedReview] = []
        var totalCount: Int?
        var sort = RatedSort.latest
        var isReviewOnly = false
        var isSortMenuPresented = false
        var isReviewMenuPresented = false
        /// 메뉴를 연 리뷰
        var selected: RatedReview?
        var isDeleteToastPresented = false
        var lastId: Int?
        var lastLikeCount: Int?
        var lastRating: Double?
    }

    enum Intent: Sendable {
        case appeared
        case disappeared
        case reloadRequested
        case sortButtonTapped
        case sortSelected(RatedSort)
        /// 목록이 움직이면 리뷰 메뉴를 닫는다
        case scrolled
        /// 스크롤 위치 값이 바뀌면 정렬 메뉴를 닫는다 (레거시는 두 메뉴를 다른 신호로 닫는다)
        case sortMenuClosedByScroll
        case backTapped
        case reviewOnlyTapped
        case itemAppeared(RatedReview)
        case firstPageLoaded(RatedPage)
        case morePageLoaded(RatedPage)
        case moreTapped(RatedReview)
        case cellTapped(RatedReview)
        case deleteTapped
        case deleteSucceeded
        case editTapped
        case toastDismissed
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared, .reloadRequested:
            // 보일 때마다, 그리고 리뷰를 저장했다는 알림을 받으면 첫 페이지를 다시 받는다 (RA2·RA12)
            return fetchFirstPage(&state)

        case .disappeared:
            state.isDeleteToastPresented = false
            return .none

        case .sortButtonTapped:
            state.isSortMenuPresented.toggle()
            return .none

        case .sortSelected(let sort):
            state.sort = sort
            state.isSortMenuPresented = false
            return fetchFirstPage(&state)

        case .scrolled:
            // 스크롤하면 열린 메뉴를 닫는다 (RA5)
            state.isReviewMenuPresented = false
            return .none

        case .sortMenuClosedByScroll:
            state.isSortMenuPresented = false
            return .none

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }

        case .reviewOnlyTapped:
            state.isReviewOnly.toggle()
            return fetchFirstPage(&state)

        case .itemAppeared(let review):
            // 마지막 칸이 보이고 7개 이상일 때. 받는 중인지는 보지 않는다 (RA4)
            guard review == state.reviews.last, state.reviews.count > 6 else {
                return .none
            }
            let (sort, lastId, lastLikeCount, lastRating) = (
                state.sort, state.lastId, state.lastLikeCount, state.lastRating
            )
            return .run { [myInfoClient] in
                guard
                    let page = try? await myInfoClient.ratedReviews(
                        sort: sort, lastId: lastId, lastLikeCount: lastLikeCount,
                        lastRating: lastRating)
                else {
                    return nil
                }
                return .morePageLoaded(page)
            }

        case .firstPageLoaded(let page):
            state.reviews = filtered(page.reviews, excluding: [], reviewOnly: state.isReviewOnly)
            state.totalCount = page.count
            updateCursor(&state, page)
            return .none

        case .morePageLoaded(let page):
            let existing = Set(state.reviews.map(\.reviewId))
            state.reviews += filtered(
                page.reviews, excluding: existing, reviewOnly: state.isReviewOnly)
            updateCursor(&state, page)
            return .none

        case .moreTapped(let review):
            state.isReviewMenuPresented.toggle()
            state.selected = review
            return .none

        case .cellTapped(let review):
            return push(DetailRoute.anime(id: review.animeId ?? 0))

        case .deleteTapped:
            state.isReviewMenuPresented = false
            state.isDeleteToastPresented = true
            let reviewId = state.selected?.reviewId ?? 0
            // 안내는 삭제 결과와 무관하게 뜨고 2초 뒤 사라진다. 삭제에 성공하면 첫 페이지를 다시 받는다 (RA9)
            return .merge([
                .run { [reviewClient] in
                    do {
                        try await reviewClient.deleteReview(id: reviewId)
                        return .deleteSucceeded
                    } catch {
                        return nil
                    }
                },
                .run(id: ToastTimer.id) { [toastDuration] in
                    try? await Task.sleep(for: toastDuration)
                    return .toastDismissed
                },
            ])

        case .deleteSucceeded:
            return fetchFirstPage(&state)

        case .editTapped:
            state.isReviewMenuPresented = false
            let review = state.selected
            return push(
                ReviewRoute.write(
                    animeId: review?.animeId ?? 0,
                    rating: review?.rating ?? 0,
                    content: review?.reviewContent ?? ""
                )
            )

        case .toastDismissed:
            state.isDeleteToastPresented = false
            return .none
        }
    }

    private enum ToastTimer {
        static let id = "deleteToast"
    }

    /// 레거시 `fetchRatedAnimeList`: 커서를 비우고 첫 페이지
    private func fetchFirstPage(_ state: inout State) -> Effect<Intent> {
        state.lastId = nil
        state.lastLikeCount = nil
        state.lastRating = nil
        let sort = state.sort
        return .run { [myInfoClient] in
            guard
                let page = try? await myInfoClient.ratedReviews(
                    sort: sort, lastId: nil, lastLikeCount: nil, lastRating: nil)
            else {
                return nil
            }
            return .firstPageLoaded(page)
        }
    }

    /// 다음 커서는 서버 커서의 lastId와 받은 마지막 리뷰의 좋아요 수·별점 (빈 페이지면 nil이 된다)
    private func updateCursor(_ state: inout State, _ page: RatedPage) {
        state.lastId = page.lastId
        state.lastLikeCount = page.reviews.last?.likeCount
        state.lastRating = page.reviews.last?.rating
    }

    /// 이미 있는 리뷰는 빼고, 리뷰만 보기면 내용 있는 것만 (RA6·RA7)
    private func filtered(_ reviews: [RatedReview], excluding ids: Set<Int?>, reviewOnly: Bool)
        -> [RatedReview]
    {
        let fresh = reviews.filter { !ids.contains($0.reviewId) }
        guard reviewOnly else {
            return fresh
        }
        return fresh.filter { !($0.reviewContent ?? "").isEmpty }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
