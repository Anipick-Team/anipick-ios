import ClientCore

/// 리뷰 작성·수정 (레거시 `AnimeAPI.writeAndEditReview`).
public protocol ReviewClient: Sendable {
    /// 별점·스포일러·내용을 저장한다. 같은 애니에 다시 보내면 수정된다.
    ///
    /// 레거시는 응답 본문의 `code`를 보지 않고, 본문을 읽기만 하면 성공으로 처리한다(`WriteReviewViewModel.swift:47-57`).
    /// 그래서 이 함수도 전송·응답 해석에 실패할 때만 던진다.
    func writeReview(animeId: Int, content: String, rating: Double, isSpoiler: Bool)
        async throws(TransportError)

    /// 내 리뷰 삭제 (`DELETE api/reviews/{id}`). 레거시처럼 응답 본문을 읽으면 성공이다(`code`를 보지 않음)
    func deleteReview(id: Int) async throws(TransportError)
    /// 가입 직후 취향 선택에서 매긴 별점을 한 번에 저장한다 (`POST api/reviews/bulk`). 응답 code는 보지 않는다
    func storeInitialRatings(_ ratings: [InitialRating]) async throws(TransportError)

    /// 최근 리뷰 (`GET api/reviews/recent`). 결과나 목록이 없으면 nil
    func recentReviews(lastId: Int?) async throws(TransportError) -> RecentReviewPage?
    /// 리뷰 좋아요 (`POST`·`DELETE api/reviews/{id}/like`). 본문 code가 200이면 true
    func setReviewLike(id: Int, liked: Bool) async throws(TransportError) -> Bool
    /// 리뷰 신고 (`POST api/reviews/{id}/report`, JSON {message}).
    /// 레거시처럼 HTTP 상태를 보지 않고 본문을 읽으면 성공이다
    func reportReview(id: Int, message: String) async throws(TransportError)
    /// 사용자 차단 (`POST api/{userId}/block-user`). 신고와 같이 본문을 읽으면 성공이다
    func blockUser(id: Int) async throws(TransportError)

    /// 애니의 리뷰 (`GET api/animes/{id}/reviews`, sort·isSpoiler·lastValue·lastId·size=10).
    /// 결과가 없으면 목록·커서가 모두 nil인 페이지
    func animeReviews(
        animeId: Int, sort: String, includesSpoiler: Bool, lastValue: String?, lastId: Int?
    )
        async throws(TransportError) -> AnimeReviewPage
    /// 이 애니의 내 리뷰 (`GET api/animes/{id}/my-review`). 없으면 nil
    func myReview(animeId: Int) async throws(TransportError) -> MyReview?
    /// 별점만 등록 (`POST api/rating/{animeId}/animes` JSON {rating}). 본문을 읽으면 성공이다
    func registerRating(animeId: Int, rating: Double) async throws(TransportError)
    /// 별점 수정 (`PATCH api/rating/{reviewId}/animes` JSON {rating}). 본문을 읽으면 성공이다
    func editRating(reviewId: Int, rating: Double) async throws(TransportError)
}

/// 애니 리뷰 한 페이지. reviews가 nil이면 화면을 바꾸지 않는다 (커서는 바꾼다)
public struct AnimeReviewPage: Equatable, Sendable {
    public let reviews: [RecentReview]?
    public let lastId: Int?
    public let lastValue: String?

    public init(reviews: [RecentReview]?, lastId: Int?, lastValue: String?) {
        self.reviews = reviews
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

/// 이 애니의 내 리뷰 (레거시 `MyReviewItem`)
public struct MyReview: Equatable, Sendable {
    public let reviewId: Int?
    public let rating: Double?
    public let content: String?
    public let createdAt: String?
    public let likeCount: Int?

    public init(
        reviewId: Int?, rating: Double?, content: String?, createdAt: String?, likeCount: Int?
    ) {
        self.reviewId = reviewId
        self.rating = rating
        self.content = content
        self.createdAt = createdAt
        self.likeCount = likeCount
    }
}

/// 최근 리뷰 한 칸 (레거시 `ReviewItem`)
public struct RecentReview: Equatable, Sendable {
    public let reviewId: Int?
    public let userId: Int?
    public let animeId: Int?
    public let animeTitle: String?
    public let animeCoverImageUrl: String?
    public let rating: Double?
    /// content가 없으면 reviewContent, 둘 다 없으면 "--"
    public let text: String
    public let nickname: String?
    /// 프로필 주소의 마지막 경로를 이미지 id로 본다 (숫자가 아니면 0). 주소가 없으면 nil
    public let profileImageId: Int?
    public let createdAt: String?
    public var likeCount: Int?
    public var isLiked: Bool?
    /// 애니 상세의 리뷰 목록만 쓴다
    public let isMine: Bool?
    public let isSpoiler: Bool?

    public init(
        reviewId: Int?, userId: Int?, animeId: Int?, animeTitle: String?,
        animeCoverImageUrl: String?,
        rating: Double?, text: String, nickname: String?, profileImageId: Int?, createdAt: String?,
        likeCount: Int?, isLiked: Bool?, isMine: Bool? = nil, isSpoiler: Bool? = nil
    ) {
        self.isMine = isMine
        self.isSpoiler = isSpoiler
        self.reviewId = reviewId
        self.userId = userId
        self.animeId = animeId
        self.animeTitle = animeTitle
        self.animeCoverImageUrl = animeCoverImageUrl
        self.rating = rating
        self.text = text
        self.nickname = nickname
        self.profileImageId = profileImageId
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.isLiked = isLiked
    }
}

public struct RecentReviewPage: Equatable, Sendable {
    public let reviews: [RecentReview]
    public let lastId: Int?

    public init(reviews: [RecentReview], lastId: Int?) {
        self.reviews = reviews
        self.lastId = lastId
    }
}

/// 취향 선택의 별점 하나
public struct InitialRating: Equatable, Sendable {
    public let animeId: Int
    public let rating: Double

    public init(animeId: Int, rating: Double) {
        self.animeId = animeId
        self.rating = rating
    }
}
