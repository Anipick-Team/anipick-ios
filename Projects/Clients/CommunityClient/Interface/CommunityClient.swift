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
}
