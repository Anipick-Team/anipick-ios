import Analytics
import CommunityClientInterface
import DetailClientInterface
import DetailInterface
import ExploreInterface
import Foundation
import MVICore
import Navigation
import ReviewClientInterface
import ReviewInterface

/// 애니 상세. 동작 목록: notes/2026-10-30-R-detail-04-anime-info.md (AD3~AD18)·R-detail-05-reviews.md (RT3~RT20)
struct AnimeDetailReducer: Reducer {
    let detailClient: any DetailClient
    let reviewClient: any ReviewClient
    let communityClient: any CommunityClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    /// 마지막으로 본 애니 저장 (홈의 "비슷한 작품"이 쓴다)
    let setLastVisitedAnimeId: @MainActor (Int) -> Void
    /// 공유 시트 (App: 문구 + Universal Link)
    let shareAnime: @MainActor (_ animeId: Int, _ title: String) -> Void
    let openURL: @MainActor (URL) -> Void
    var reviewRefreshDelay: Duration = .milliseconds(200)
    var toastDuration: Duration = .seconds(2)

    static let communityInquiryURL = URL(string: "https://forms.gle/zDiFyZnNwm8kFi2A7")!

    enum WatchStatus: String, CaseIterable, Sendable {
        case wantToWatch = "볼 애니"
        case watching = "보는 중"
        case finished = "다 본 애니"
        case empty = ""

        /// 서버 값 (WATCHLIST·WATCHING·FINISHED)
        var status: String {
            switch self {
            case .wantToWatch:
                return "WATCHLIST"
            case .watching:
                return "WATCHING"
            case .finished:
                return "FINISHED"
            case .empty:
                return ""
            }
        }

        init(status: String?) {
            self = Self.allCases.first { $0 != .empty && $0.status == status } ?? .empty
        }
    }

    /// 리뷰 정렬 (레거시 `SortOption`)
    enum ReviewSort: String, CaseIterable, Sendable {
        case latest = "최신순"
        case likes = "좋아요 순"
        case highRating = "평가 높은 순"
        case lowRating = "평가 낮은 순"

        var request: String {
            switch self {
            case .latest:
                return "latest"
            case .likes:
                return "likes"
            case .highRating:
                return "ratingDesc"
            case .lowRating:
                return "ratingAsc"
            }
        }
    }

    enum Toast: Sendable {
        case blocked
        case reported
        case ratingWritten
    }

    enum Tab: String, CaseIterable, Sendable {
        case info = "작품 정보"
        case reviews = "리뷰"
        case community = "커뮤니티"
    }

    struct State: Equatable {
        let animeId: Int
        var info: AnimeInfo?
        var averageRating = ""
        var reviewCount = 0
        var isLiked = false
        var watchStatus = WatchStatus.empty
        var cast: [CastMember] = []
        var series: [DetailAnime] = []
        var recommendations: [DetailAnime] = []
        var selectedTab = Tab.info
        var previewImageURL: URL?
        var isCommunityMissingPresented = false
        var isCheckingCommunity = false
        var didStart = false
        // 리뷰 탭
        var reviews: [RecentReview] = []
        var reviewLastId: Int?
        var reviewLastValue: String?
        var showsSpoilers = false
        var reviewSort = ReviewSort.latest
        var isSortMenuPresented = false
        var myReviewContent = ""
        var myReviewCreatedAt = ""
        var storedRating = 0.0
        var myLikeCount = 0
        var myReviewId = 0
        /// 별점 상자에서 고른 값 (레거시 View의 @State starRating)
        var pendingRating = 0.0
        var isMyReviewMenuPresented = false
        var isBlockMenuPresented = false
        /// ⋮ 버튼 아래쪽의 화면 위치 (메뉴를 그 아래에 띄운다)
        var menuAnchorMaxY: Double = 0
        var selectedReviewId = 0
        var selectedUserId = 0
        var isReportConfirmPresented = false
        var isReportReasonPresented = false
        var isBlockConfirmPresented = false
        var isBlockToastPresented = false
        var isReportToastPresented = false
        var isRatingToastPresented = false

        init(animeId: Int) {
            self.animeId = animeId
        }

        /// 배너가 없으면 표지, 둘 다 없으면 nil (공백만 있는 주소도 없음으로 본다)
        var bannerURL: URL? {
            return Self.validURL(info?.bannerImageUrl) ?? coverURL
        }

        var coverURL: URL? {
            return Self.validURL(info?.coverImageUrl)
        }

        private static func validURL(_ string: String?) -> URL? {
            guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
                !trimmed.isEmpty
            else {
                return nil
            }
            return URL(string: trimmed)
        }
    }

    enum Intent: Sendable {
        case appeared
        case infoLoaded(AnimeInfo)
        case infoFailed(any Error)
        case castLoaded([CastMember])
        case seriesLoaded([DetailAnime])
        case recommendationsLoaded([DetailAnime])
        case likeTapped
        case likeChanged(Bool)
        case watchStatusTapped(WatchStatus)
        case watchStatusPosted(WatchStatus, code: Int)
        case shareTapped
        case tabSelected(Tab)
        case communityTapped
        case communityChecked(AnimeBoard?)
        case communityCheckFailed
        case communityMissingClosed
        case communityInquiryTapped
        case imageTapped(URL?)
        case previewClosed
        case castHeaderTapped
        case castTapped(CastMember)
        case seriesHeaderTapped
        case recommendationsHeaderTapped
        case animeTapped(animeId: Int?)
        case producerTapped(studioId: Int?)
        case backTapped
        // 리뷰 탭
        case reviewTabAppeared
        case reviewTabRefreshed
        case reviewTabDisappeared
        case reviewsLoaded(AnimeReviewPage, appending: Bool)
        case myReviewLoaded(MyReview)
        case reviewAppeared(RecentReview)
        case spoilerToggled
        case sortButtonTapped
        case sortSelected(ReviewSort)
        case ratingDragged(Double)
        case ratingRegistered
        case myRatingDragged(Double)
        case writeDetailTapped
        case reviewLikeTapped(RecentReview, liked: Bool)
        case reviewMoreTapped(RecentReview, anchorMaxY: Double)
        case myReviewMoreTapped(anchorMaxY: Double)
        case scrolled
        case myReviewDeleteTapped
        case myReviewDeleted
        case myReviewEditTapped
        case reportMenuTapped
        case reportConfirmCancelled
        case reportConfirmNextTapped
        case reportReasonCancelled
        case reportReasonConfirmed(String)
        case reported
        case blockMenuTapped
        case blockCancelled
        case blockConfirmed
        case blocked
        case toastExpired(Toast)
        case disappeared
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 마지막으로 본 애니로 저장한다. 내용은 처음 한 번만 받는다 (레거시: ViewModel을 만들 때)
            setLastVisitedAnimeId(state.animeId)
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            return initialLoads(&state)

        case .infoLoaded(let info):
            state.info = info
            state.averageRating = info.averageRating ?? "-"
            state.reviewCount = info.reviewCount ?? 0
            state.isLiked = info.isLiked ?? false
            state.watchStatus = WatchStatus(status: info.watchStatus)
            let animeId = state.animeId
            return log(.animeDetailView(animeId: animeId, animeTitle: info.title))

        case .infoFailed(let error):
            return .run { [analytics] in
                analytics.logError(error, context: "fetchAnimationInfo")
                return nil
            }

        case .castLoaded(let cast):
            state.cast = cast
            return .none

        case .seriesLoaded(let series):
            state.series = series
            return .none

        case .recommendationsLoaded(let recommendations):
            state.recommendations = recommendations
            return .none

        case .likeTapped:
            // 응답을 받은 뒤 바꾼다 (낙관적이지 않음). 받는 중인지는 보지 않는다
            let (animeId, liked) = (state.animeId, !state.isLiked)
            return .run { [detailClient] in
                guard (try? await detailClient.setAnimeLike(id: animeId, liked: liked)) != nil
                else {
                    return nil
                }
                return .likeChanged(liked)
            }

        case .likeChanged(let liked):
            state.isLiked.toggle()
            let (animeId, title) = (state.animeId, state.info?.title)
            return log(
                liked
                    ? .animeLike(animeId: animeId, animeTitle: title)
                    : .animeUnlike(animeId: animeId, animeTitle: title))

        case .watchStatusTapped(let status):
            if status == state.watchStatus {
                state.watchStatus = .empty
                return deleteWatchStatus(state.animeId)
            }
            state.watchStatus = status
            return postWatchStatus(state.animeId, status)

        case .watchStatusPosted(let status, let code):
            // 128(이미 상태가 있음)이면 지우고 다시 보낸다 (둘을 기다리지 않고 함께 — 레거시 그대로)
            guard code == 128 else {
                return .none
            }
            return .merge([
                deleteWatchStatus(state.animeId), postWatchStatus(state.animeId, status),
            ])

        case .shareTapped:
            guard let info = state.info else {
                return .none
            }
            let title = info.title ?? "애니픽"
            shareAnime(info.animeId, title)
            return log(.animeShare(animeId: info.animeId, animeTitle: title))

        case .tabSelected(let tab):
            state.selectedTab = tab
            return .none

        case .communityTapped:
            guard let info = state.info, !state.isCheckingCommunity else {
                return .none
            }
            state.isCheckingCommunity = true
            return .run { [communityClient] in
                do {
                    return .communityChecked(try await communityClient.board(animeId: info.animeId))
                } catch {
                    return .communityCheckFailed
                }
            }

        case .communityChecked(let board):
            state.isCheckingCommunity = false
            guard let info = state.info, let board, board.hasBoard == true,
                let seriesId = board.seriesId
            else {
                state.isCommunityMissingPresented = true
                return .none
            }
            let genres = board.genres ?? []
            let route = ExploreRoute.communityBoard(
                seriesId: seriesId, animeTitle: board.title ?? info.title ?? "애니메이션",
                coverImageUrl: board.coverImageUrl ?? info.coverImageUrl,
                genreNames: genres.isEmpty ? (info.genres ?? []) : genres)
            return push(route)

        case .communityCheckFailed:
            state.isCheckingCommunity = false
            return .none

        case .communityMissingClosed:
            state.isCommunityMissingPresented = false
            return .none

        case .communityInquiryTapped:
            state.isCommunityMissingPresented = false
            openURL(Self.communityInquiryURL)
            return .none

        case .imageTapped(let url):
            state.previewImageURL = url
            return .none

        case .previewClosed:
            state.previewImageURL = nil
            return .none

        case .castHeaderTapped:
            return push(DetailRoute.cast(animeId: state.info?.animeId ?? state.animeId))

        case .castTapped(let member):
            return push(DetailRoute.voiceActor(id: member.voiceActor?.id ?? 0))

        case .seriesHeaderTapped:
            return push(
                DetailRoute.series(
                    animeId: state.info?.animeId ?? state.animeId,
                    animeTitle: state.info?.title ?? "-"))

        case .recommendationsHeaderTapped:
            return push(
                DetailRoute.recommendations(
                    animeId: state.info?.animeId ?? state.animeId,
                    animeTitle: state.info?.title ?? "-"))

        case .animeTapped(let animeId):
            return push(DetailRoute.anime(id: animeId ?? 0))

        case .producerTapped(let studioId):
            return push(DetailRoute.producer(id: studioId ?? 0))

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }

        default:
            return reduceReviews(into: &state, intent: intent)
        }
    }

    /// 리뷰 탭 (레거시 `ReviewDetailInfoView`와 상세 화면의 리뷰 메뉴·신고·차단)
    private func reduceReviews(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .reviewTabAppeared:
            // 탭이 보일 때마다 별점 상자를 저장된 별점으로 맞추고, 0.2초 뒤 내 리뷰·리뷰를 다시 받는다
            state.pendingRating = state.storedRating
            return .run { [reviewRefreshDelay] in
                try? await Task.sleep(for: reviewRefreshDelay)
                return .reviewTabRefreshed
            }

        case .reviewTabRefreshed:
            return .merge([fetchMyReview(state.animeId), fetchReviews(&state)])

        case .reviewTabDisappeared:
            state.isRatingToastPresented = false
            return .none

        case .reviewsLoaded(let page, let appending):
            if let reviews = page.reviews {
                // 스포일러를 끄면 화면에서 거른다 (isSpoiler가 없으면 빠진다 — 레거시 그대로)
                let visible =
                    state.showsSpoilers ? reviews : reviews.filter { $0.isSpoiler == false }
                state.reviews = appending ? state.reviews + visible : visible
            }
            state.reviewLastId = page.lastId
            state.reviewLastValue = page.lastValue
            return .none

        case .myReviewLoaded(let review):
            state.myReviewContent = review.content ?? ""
            state.myReviewCreatedAt = review.createdAt ?? ""
            state.storedRating = review.rating ?? 0
            state.myLikeCount = review.likeCount ?? 0
            state.myReviewId = review.reviewId ?? 0
            return .none

        case .reviewAppeared(let review):
            guard review.reviewId == state.reviews.last?.reviewId else {
                return .none
            }
            return loadReviews(state, appending: true)

        case .spoilerToggled:
            state.showsSpoilers.toggle()
            return fetchReviews(&state)

        case .sortButtonTapped:
            state.isSortMenuPresented.toggle()
            return .none

        case .sortSelected(let sort):
            state.reviewSort = sort
            state.isSortMenuPresented.toggle()
            return fetchReviews(&state)

        case .ratingDragged(let rating):
            // 끌 때마다 보낸다: 리뷰가 없으면 별점 등록, 있으면 별점 수정
            state.pendingRating = rating
            let (animeId, reviewId) = (state.animeId, state.myReviewId)
            if reviewId == 0 {
                return .run { [reviewClient] in
                    return
                        (try? await reviewClient.registerRating(animeId: animeId, rating: rating))
                        == nil
                        ? nil : .ratingRegistered
                }
            }
            return .run { [reviewClient] in
                try? await reviewClient.editRating(reviewId: reviewId, rating: rating)
                return nil
            }

        case .ratingRegistered:
            return toggleToast(&state.isRatingToastPresented, .ratingWritten)

        case .myRatingDragged(let rating):
            // "내 리뷰" 카드의 별점은 표시만 바뀐다
            state.storedRating = rating
            state.pendingRating = rating
            return .none

        case .writeDetailTapped:
            state.storedRating = state.pendingRating
            let (animeId, rating) = (state.animeId, state.pendingRating)
            let register: Effect<Intent> = .run { [reviewClient] in
                try? await reviewClient.registerRating(animeId: animeId, rating: rating)
                return nil
            }
            return .merge([
                register, push(ReviewRoute.write(animeId: animeId, rating: rating, content: "")),
            ])

        case .reviewLikeTapped(let review, let liked):
            // 칸이 표시를 들고 있다. 요청 결과는 보지 않는다
            let reviewId = review.reviewId ?? 0
            return .run { [reviewClient] in
                _ = try? await reviewClient.setReviewLike(id: reviewId, liked: liked)
                return nil
            }

        case .reviewMoreTapped(let review, let anchorMaxY):
            state.menuAnchorMaxY = anchorMaxY
            if review.isMine ?? false {
                state.isMyReviewMenuPresented.toggle()
            } else {
                state.selectedReviewId = review.reviewId ?? 0
                state.selectedUserId = review.userId ?? 0
                state.isBlockMenuPresented.toggle()
            }
            return .none

        case .myReviewMoreTapped(let anchorMaxY):
            state.menuAnchorMaxY = anchorMaxY
            state.isMyReviewMenuPresented.toggle()
            return .none

        case .scrolled:
            state.isMyReviewMenuPresented = false
            state.isBlockMenuPresented = false
            return .none

        case .myReviewDeleteTapped:
            state.isMyReviewMenuPresented.toggle()
            let reviewId = state.myReviewId
            return .run { [reviewClient] in
                return (try? await reviewClient.deleteReview(id: reviewId)) == nil
                    ? nil : .myReviewDeleted
            }

        case .myReviewDeleted:
            // 내 리뷰가 없다는 응답은 화면을 바꾸지 않아, 지운 리뷰가 남는다 (레거시 그대로)
            return .merge([fetchReviews(&state), fetchMyReview(state.animeId)])

        case .myReviewEditTapped:
            state.isMyReviewMenuPresented.toggle()
            return push(
                ReviewRoute.write(
                    animeId: state.animeId, rating: state.storedRating,
                    content: state.myReviewContent))

        case .reportMenuTapped:
            state.isBlockMenuPresented = false
            state.isReportConfirmPresented.toggle()
            return .none

        case .reportConfirmCancelled:
            state.isReportConfirmPresented.toggle()
            return .none

        case .reportConfirmNextTapped:
            state.isReportConfirmPresented.toggle()
            state.isReportReasonPresented.toggle()
            return .none

        case .reportReasonCancelled:
            state.isReportReasonPresented.toggle()
            return .none

        case .reportReasonConfirmed(let reason):
            state.isReportReasonPresented.toggle()
            let reviewId = state.selectedReviewId
            return .run { [reviewClient] in
                return (try? await reviewClient.reportReview(id: reviewId, message: reason)) == nil
                    ? nil : .reported
            }

        case .reported:
            return .merge([
                toggleToast(&state.isReportToastPresented, .reported), fetchReviews(&state),
            ])

        case .blockMenuTapped:
            state.isBlockMenuPresented = false
            state.isBlockConfirmPresented.toggle()
            return .none

        case .blockCancelled:
            state.isBlockConfirmPresented.toggle()
            return .none

        case .blockConfirmed:
            state.isBlockConfirmPresented.toggle()
            let userId = state.selectedUserId
            return .run { [reviewClient] in
                return (try? await reviewClient.blockUser(id: userId)) == nil ? nil : .blocked
            }

        case .blocked:
            return .merge([
                toggleToast(&state.isBlockToastPresented, .blocked), fetchReviews(&state),
            ])

        case .toastExpired(let toast):
            switch toast {
            case .blocked:
                state.isBlockToastPresented = false
            case .reported:
                state.isReportToastPresented = false
            case .ratingWritten:
                state.isRatingToastPresented = false
            }
            return .none

        case .disappeared:
            state.isBlockToastPresented = false
            state.isReportToastPresented = false
            return .none

        default:
            return .none
        }
    }

    /// 레거시 `fetchReview`: 커서를 비우고 첫 페이지로 바꾼다 (받는 중인지는 보지 않는다)
    private func fetchReviews(_ state: inout State) -> Effect<Intent> {
        state.reviewLastId = nil
        state.reviewLastValue = nil
        return loadReviews(state, appending: false)
    }

    private func loadReviews(_ state: State, appending: Bool) -> Effect<Intent> {
        let (animeId, sort, spoilers) = (
            state.animeId, state.reviewSort.request, state.showsSpoilers
        )
        let (lastValue, lastId) = (state.reviewLastValue, state.reviewLastId)
        return .run { [reviewClient] in
            guard
                let page = try? await reviewClient.animeReviews(
                    animeId: animeId, sort: sort, includesSpoiler: spoilers, lastValue: lastValue,
                    lastId: lastId)
            else {
                return nil
            }
            return .reviewsLoaded(page, appending: appending)
        }
    }

    private func fetchMyReview(_ animeId: Int) -> Effect<Intent> {
        return .run { [reviewClient] in
            guard let review = (try? await reviewClient.myReview(animeId: animeId)) ?? nil else {
                return nil
            }
            return .myReviewLoaded(review)
        }
    }

    /// 레거시 PopupView 토스트: 토글로 띄우고(떠 있으면 닫힘) 2초 뒤 닫는다
    private func toggleToast(_ isPresented: inout Bool, _ toast: Toast) -> Effect<Intent> {
        isPresented.toggle()
        guard isPresented else {
            return .none
        }
        return .run { [toastDuration] in
            try? await Task.sleep(for: toastDuration)
            return .toastExpired(toast)
        }
    }

    /// 레거시 ViewModel init의 요청들. 관련 작품 목록(series, size 10) 결과는 화면에서 쓰지 않는다
    private func initialLoads(_ state: inout State) -> Effect<Intent> {
        let animeId = state.animeId
        return .merge([
            fetchReviews(&state),
            fetchMyReview(animeId),
            .run { [detailClient] in
                do {
                    return .infoLoaded(try await detailClient.animeInfo(id: animeId))
                } catch {
                    return .infoFailed(error)
                }
            },
            .run { [detailClient] in
                _ = try? await detailClient.series(animeId: animeId, lastId: nil)
                return nil
            },
            .run { [detailClient] in
                guard let cast = try? await detailClient.detailCast(animeId: animeId) else {
                    return nil
                }
                return .castLoaded(cast)
            },
            .run { [detailClient] in
                guard let series = try? await detailClient.detailSeries(animeId: animeId) else {
                    return nil
                }
                return .seriesLoaded(series)
            },
            .run { [detailClient] in
                guard let animes = try? await detailClient.detailRecommendations(animeId: animeId)
                else {
                    return nil
                }
                return .recommendationsLoaded(animes)
            },
        ])
    }

    private func postWatchStatus(_ animeId: Int, _ status: WatchStatus) -> Effect<Intent> {
        return .run { [detailClient] in
            guard
                let code = try? await detailClient.setWatchStatus(
                    animeId: animeId, status: status.status)
            else {
                return nil
            }
            return .watchStatusPosted(status, code: code)
        }
    }

    private func deleteWatchStatus(_ animeId: Int) -> Effect<Intent> {
        return .run { [detailClient] in
            try? await detailClient.deleteWatchStatus(animeId: animeId)
            return nil
        }
    }

    private func log(_ event: AnalyticsEvent) -> Effect<Intent> {
        return .run { [analytics] in
            analytics.log(event)
            return nil
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
