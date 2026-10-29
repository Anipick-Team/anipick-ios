import ClientCore
import Foundation

/// 커뮤니티 게시판(애니 시리즈) 한 칸 (레거시 `CommunityBoard`)
public struct CommunityBoard: Hashable, Sendable {
    public let seriesId: Int
    public let title: String?
    public let coverImageUrl: String?
    public let genres: [String]

    public init(seriesId: Int, title: String?, coverImageUrl: String?, genres: [String]) {
        self.seriesId = seriesId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.genres = genres
    }
}

public struct CommunityBoardPage: Equatable, Sendable {
    public let boards: [CommunityBoard]
    public let lastId: Int?
    public let lastValue: String?

    public init(boards: [CommunityBoard], lastId: Int?, lastValue: String?) {
        self.boards = boards
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

/// 게시판 글 한 칸 (레거시 `CommunityPost`)
public struct CommunityPost: Identifiable, Equatable, Sendable {
    public let id: Int
    /// 없으면 "익명"
    public let authorName: String
    /// 프로필 주소의 마지막 경로를 id로 본 인증 이미지 주소 (숫자가 아니면 nil)
    public let authorImageURL: URL?
    public let date: String
    public let title: String
    public let content: String
    /// 첫 첨부 사진 (썸네일 1장만 내려온다)
    public let thumbnailURL: URL?
    /// 첨부 사진 전체 개수
    public let imageCount: Int
    public let likeCount: Int
    public let commentCount: Int
    public let isSpoiler: Bool

    public init(
        id: Int, authorName: String, authorImageURL: URL?, date: String, title: String,
        content: String, thumbnailURL: URL?, imageCount: Int, likeCount: Int, commentCount: Int,
        isSpoiler: Bool
    ) {
        self.id = id
        self.authorName = authorName
        self.authorImageURL = authorImageURL
        self.date = date
        self.title = title
        self.content = content
        self.thumbnailURL = thumbnailURL
        self.imageCount = imageCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isSpoiler = isSpoiler
    }
}

public struct CommunityPostPage: Equatable, Sendable {
    public let posts: [CommunityPost]
    public let lastId: Int?
    public let lastValue: String?

    public init(posts: [CommunityPost], lastId: Int?, lastValue: String?) {
        self.posts = posts
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

/// 게시글 상세 (레거시 `CommunityDetailPost`)
public struct CommunityPostDetail: Equatable, Sendable {
    public let postId: Int
    /// 없으면 0 (수정으로 가지 못한다)
    public let seriesId: Int
    /// 없으면 "애니메이션"
    public let animeTitle: String
    public let authorName: String
    public let authorImageURL: URL?
    public let date: String
    public let isSpoiler: Bool
    public let imageIds: [Int]
    public let imageURLs: [URL]
    public let title: String
    public let body: String
    public let viewCount: Int
    public var likeCount: Int
    public let commentCount: Int
    public var isLiked: Bool
    public let isMine: Bool

    public init(
        postId: Int, seriesId: Int, animeTitle: String, authorName: String, authorImageURL: URL?,
        date: String, isSpoiler: Bool, imageIds: [Int], imageURLs: [URL], title: String,
        body: String,
        viewCount: Int, likeCount: Int, commentCount: Int, isLiked: Bool, isMine: Bool
    ) {
        self.postId = postId
        self.seriesId = seriesId
        self.animeTitle = animeTitle
        self.authorName = authorName
        self.authorImageURL = authorImageURL
        self.date = date
        self.isSpoiler = isSpoiler
        self.imageIds = imageIds
        self.imageURLs = imageURLs
        self.title = title
        self.body = body
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.isMine = isMine
    }
}

/// 댓글 (레거시 `CommunityComment`·`CommunityReply`). 답글은 replies가 비어 있다
public struct CommunityComment: Identifiable, Equatable, Sendable {
    public let id: Int
    public let authorName: String
    public let authorImageURL: URL?
    public let date: String
    /// 지운 댓글은 "삭제된 댓글입니다."
    public let content: String
    public var likeCount: Int
    public var isLiked: Bool
    public let isMine: Bool
    public var replies: [CommunityComment]

    public init(
        id: Int, authorName: String, authorImageURL: URL?, date: String, content: String,
        likeCount: Int, isLiked: Bool, isMine: Bool, replies: [CommunityComment]
    ) {
        self.id = id
        self.authorName = authorName
        self.authorImageURL = authorImageURL
        self.date = date
        self.content = content
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.isMine = isMine
        self.replies = replies
    }
}

public struct CommunityCommentPage: Equatable, Sendable {
    public let comments: [CommunityComment]
    public let lastId: Int?

    public init(comments: [CommunityComment], lastId: Int?) {
        self.comments = comments
        self.lastId = lastId
    }
}

/// 신고 대상 (레거시 `CommunityReportTarget`)
public enum ReportTarget: String, Hashable, Sendable {
    case post = "POST"
    case comment = "COMMENT"
}

/// 신고 유형 (레거시 `CommunityReportCategory`)
public enum ReportCategory: String, CaseIterable, Hashable, Sendable {
    case abuse = "ABUSE"
    case privacy = "PRIVACY"
    case spam = "SPAM"
    case illegal = "ILLEGAL"
    case etc = "ETC"

    public var displayName: String {
        switch self {
        case .abuse:
            return "욕설/비하/혐오 표현"
        case .privacy:
            return "개인정보 노출"
        case .spam:
            return "도배/스팸/광고성 내용"
        case .illegal:
            return "불법/유해/부적절한 내용"
        case .etc:
            return "기타 운영정책 위반"
        }
    }
}

/// 글 작성·수정 내용 (레거시 `CommunityPostRequest`·`CommunityPostUpdateRequest`)
public struct PostDraft: Equatable, Sendable {
    public let title: String
    public let content: String
    public let isSpoiler: Bool
    /// 화면 순서대로의 첨부 사진 id
    public let imageIds: [Int]

    public init(title: String, content: String, isSpoiler: Bool, imageIds: [Int]) {
        self.title = title
        self.content = content
        self.isSpoiler = isSpoiler
        self.imageIds = imageIds
    }
}

/// 글 저장 결과. 서버는 업무 오류도 HTTP 200으로 보내고 본문 code로 가른다
public enum PostSaveOutcome: Equatable, Sendable {
    case saved
    /// code가 200이 아님. 서버가 준 안내 문구(errorValue)
    case rejected(message: String?)
}

public protocol CommunityClient: Sendable {
    /// 애니 게시판 글 목록 (`GET api/community/boards/{seriesId}/posts`, 20개씩).
    /// sort는 "latest"·"popularMonthly"·"popularWeekly"·"popularDaily"
    func posts(seriesId: Int, sort: String, lastValue: String?, lastId: Int?)
        async throws(TransportError) -> CommunityPostPage
    /// 첨부 사진 id를 받을 주소 (`{서버}api/image/{id}`, 인증 필요)
    func imageURL(id: Int) -> URL
    /// 글 첨부 사진 올리기 (multipart `postImageFile`). 서버가 id를 주지 않으면 nil
    func uploadPostImage(jpeg: Data, fileName: String) async throws(TransportError) -> Int?
    /// 글 작성 (`POST api/community/posts`). 사진이 없으면 imageIds를 보내지 않는다
    func createPost(seriesId: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    /// 글 수정 (`PATCH api/community/posts/{id}`). 사진은 전량 교체라 비어 있어도 보낸다
    func updatePost(id: Int, _ draft: PostDraft) async throws(TransportError) -> PostSaveOutcome

    /// 커뮤니티 게시판 탐색 (`GET api/community/explore/boards`, 20개씩). sort는 "popular"·"latest"
    func exploreBoards(sort: String, keyword: String?, lastValue: String?, lastId: Int?)
        async throws(TransportError) -> CommunityBoardPage
    /// 게시글 상세 (`GET api/community/posts/{id}`). 결과가 없으면 `.decoding`
    func postDetail(id: Int) async throws(TransportError) -> CommunityPostDetail
    /// 댓글 (`GET api/community/posts/{id}/comments`, 20개씩)
    func comments(postId: Int, lastId: Int?) async throws(TransportError) -> CommunityCommentPage
    /// 게시글 좋아요 (`POST`·`DELETE api/community/posts/{id}/like`)
    func setPostLike(id: Int, liked: Bool) async throws(TransportError)
    /// 댓글·답글 좋아요 (`POST`·`DELETE api/community/comments/{id}/like`)
    func setCommentLike(id: Int, liked: Bool) async throws(TransportError)
    /// 댓글 작성 (`POST api/community/posts/{id}/comments`). parentCommentId가 있으면 답글
    func createComment(postId: Int, content: String, parentCommentId: Int?)
        async throws(TransportError)
    /// 댓글 수정 (`PATCH api/community/comments/{id}`)
    func updateComment(id: Int, content: String) async throws(TransportError)
    /// 게시글 삭제 (`DELETE api/community/posts/{id}`)
    func deletePost(id: Int) async throws(TransportError)
    /// 댓글 삭제 (`DELETE api/community/comments/{id}`)
    func deleteComment(id: Int) async throws(TransportError)
    /// 신고 (`POST api/community/reports`)
    func report(target: ReportTarget, targetId: Int, category: ReportCategory)
        async throws(TransportError)
}
