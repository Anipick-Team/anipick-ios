import ClientCore
import Foundation

/// 볼·보는 중·다 본 애니 (서버 `status` 값)
public enum WatchStatus: String, CaseIterable, Sendable {
    case watchList = "WATCHLIST"
    case watching = "WATCHING"
    case finished = "FINISHED"
}

/// 목록의 애니 한 칸 (레거시 `ToWatchAnime`·`LikedAnime`)
public struct MyAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    /// 다 본 애니에서만 온다
    public let myRating: Double?

    public init(animeId: Int?, title: String?, coverImageUrl: String?, myRating: Double? = nil) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.myRating = myRating
    }
}

/// 좋아요한 인물 한 칸 (레거시 `LikedRatedPerson`)
public struct MyPerson: Hashable, Sendable {
    public let personId: Int?
    public let name: String?
    public let profileImageUrl: String?

    public init(personId: Int?, name: String?, profileImageUrl: String?) {
        self.personId = personId
        self.name = name
        self.profileImageUrl = profileImageUrl
    }
}

/// 한 페이지. `count`는 전체 개수
public struct MyPage<Item: Hashable & Sendable>: Equatable, Sendable {
    public let count: Int
    public let items: [Item]
    /// 다음 페이지 커서. 서버가 비워 보낼 수 있다
    public let lastId: Int?

    public init(count: Int, items: [Item], lastId: Int?) {
        self.count = count
        self.items = items
        self.lastId = lastId
    }
}

/// 평가한 작품 정렬 (서버 `sort` 값)
public enum RatedSort: String, CaseIterable, Sendable {
    case latest
    case likes
    case ratingDesc
    case ratingAsc
}

/// 평가한 작품 한 칸 (레거시 `MyReview`)
public struct RatedReview: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let rating: Double?
    public let reviewId: Int?
    public let reviewContent: String?
    public let createdAt: String?
    public let likeCount: Int?

    public init(
        animeId: Int?,
        title: String?,
        coverImageUrl: String?,
        rating: Double?,
        reviewId: Int?,
        reviewContent: String?,
        createdAt: String?,
        likeCount: Int?
    ) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.rating = rating
        self.reviewId = reviewId
        self.reviewContent = reviewContent
        self.createdAt = createdAt
        self.likeCount = likeCount
    }
}

/// 평가한 작품 한 페이지. 개수·커서는 서버가 비워 보낼 수 있다
public struct RatedPage: Equatable, Sendable {
    public let count: Int?
    public let lastId: Int?
    public let reviews: [RatedReview]

    public init(count: Int?, lastId: Int?, reviews: [RatedReview]) {
        self.count = count
        self.lastId = lastId
        self.reviews = reviews
    }
}

/// 내 커뮤니티 게시글 (레거시 `MyCommunityPost`)
public struct MyPost: Hashable, Sendable {
    public let postId: Int
    public let animeTitle: String?
    public let animeCoverImageUrl: String?
    /// 첫 번째 장르 이름
    public let genre: String?
    public let title: String?
    public let content: String?
    /// 첨부 대표 이미지 주소 (인증 필요)
    public let thumbnailURL: URL?
    public let isSpoiler: Bool?
    public let viewCount: Int?
    public let likeCount: Int?
    public let commentCount: Int?
    public let createdAt: String?

    public init(
        postId: Int, animeTitle: String?, animeCoverImageUrl: String?, genre: String?,
        title: String?, content: String?, thumbnailURL: URL?, isSpoiler: Bool?,
        viewCount: Int?, likeCount: Int?, commentCount: Int?, createdAt: String?
    ) {
        self.postId = postId
        self.animeTitle = animeTitle
        self.animeCoverImageUrl = animeCoverImageUrl
        self.genre = genre
        self.title = title
        self.content = content
        self.thumbnailURL = thumbnailURL
        self.isSpoiler = isSpoiler
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
    }
}

/// 내 커뮤니티 댓글 (레거시 `MyCommunityComment`)
public struct MyComment: Hashable, Sendable {
    public let commentId: Int
    public let postId: Int?
    public let animeTitle: String?
    public let animeCoverImageUrl: String?
    public let genre: String?
    public let postTitle: String?
    public let content: String?
    public let likeCount: Int?
    public let createdAt: String?

    public init(
        commentId: Int, postId: Int?, animeTitle: String?, animeCoverImageUrl: String?,
        genre: String?, postTitle: String?, content: String?, likeCount: Int?, createdAt: String?
    ) {
        self.commentId = commentId
        self.postId = postId
        self.animeTitle = animeTitle
        self.animeCoverImageUrl = animeCoverImageUrl
        self.genre = genre
        self.postTitle = postTitle
        self.content = content
        self.likeCount = likeCount
        self.createdAt = createdAt
    }
}

/// 내 콘텐츠 한 페이지. 개수·커서는 서버가 비워 보낼 수 있다
public struct ContentPage<Item: Hashable & Sendable>: Equatable, Sendable {
    public let count: Int?
    public let lastId: Int?
    public let items: [Item]

    public init(count: Int?, lastId: Int?, items: [Item]) {
        self.count = count
        self.lastId = lastId
        self.items = items
    }
}

/// 마이페이지 목록 (레거시 `MyInfoAPI`)
public protocol MyInfoClient: Sendable {
    /// 20개씩
    func watchList(_ status: WatchStatus, lastId: Int?) async throws(TransportError) -> MyPage<
        MyAnime
    >
    /// 20개씩
    func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime>
    /// 30개씩
    func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson>
    /// 평가한 작품 20개씩. `reviewOnly`는 레거시처럼 항상 false로 보낸다 (리뷰만 보기는 화면에서 거른다)
    func ratedReviews(sort: RatedSort, lastId: Int?, lastLikeCount: Int?, lastRating: Double?)
        async throws(TransportError) -> RatedPage

    /// 내 게시글 20개씩 (`api/mypage/community/posts`)
    func myPosts(lastId: Int?) async throws(TransportError) -> ContentPage<MyPost>
    /// 내 댓글 20개씩 (`api/mypage/community/comments`)
    func myComments(lastId: Int?) async throws(TransportError) -> ContentPage<MyComment>
}
