import ClientCore
import CommunityClientInterface
import Foundation
import Networking

public struct LiveCommunityClient: CommunityClient {
    private let client: HTTPClient
    private let imageBaseURL: URL

    /// - Parameters:
    ///   - client: 인증 클라이언트
    ///   - imageBaseURL: 이미지 id를 주소로 바꿀 때 쓰는 서버 주소 (`{주소}api/image/{id}`)
    public init(client: HTTPClient, imageBaseURL: URL) {
        self.client = client
        self.imageBaseURL = imageBaseURL
    }

    public func posts(seriesId: Int, sort: String, lastValue: String?, lastId: Int?)
        async throws(TransportError) -> CommunityPostPage
    {
        let response = try await client.send(
            Self.postsEndpoint(seriesId: seriesId, sort: sort, lastValue: lastValue, lastId: lastId)
        )
        let result = response.result
        return CommunityPostPage(
            posts: (result?.posts ?? []).map(post),
            lastId: result?.cursor?.lastId,
            lastValue: result?.cursor?.lastValue
        )
    }

    static func postsEndpoint(seriesId: Int, sort: String, lastValue: String?, lastId: Int?)
        -> Endpoint<PostsResult>
    {
        let parameters: [String: String?] = [
            "sort": sort, "lastValue": lastValue, "lastId": lastId.map(String.init), "size": "20",
        ]
        return Endpoint(
            method: .get,
            path: "api/community/boards/\(seriesId)/posts",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }

    /// 레거시 `CommunityViewModel.mapPost`
    private func post(_ dto: PostsResult.Post) -> CommunityPost {
        return CommunityPost(
            id: dto.postId,
            authorName: dto.nickname ?? "익명",
            authorImageURL: profileImageURL(dto.profileImageUrl),
            date: dto.createdAt ?? "",
            title: dto.title ?? "",
            content: dto.content ?? "",
            thumbnailURL: dto.thumbnailImageId.map(imageURL(id:)),
            imageCount: dto.imageCount ?? (dto.thumbnailImageId == nil ? 0 : 1),
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0,
            isSpoiler: dto.isSpoiler ?? false
        )
    }

    /// 레거시 `CommunityProfileAvatar`: 프로필 주소의 마지막 경로를 이미지 id로 본다
    func profileImageURL(_ value: String?) -> URL? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty,
            let id = value.split(separator: "/").last.flatMap({ Int($0) })
        else {
            return nil
        }
        return imageURL(id: id)
    }

    public func postDetail(id: Int) async throws(TransportError) -> CommunityPostDetail {
        let dto = try await client.send(
            Endpoint<DetailResult>(
                method: .get, path: "api/community/posts/\(id)", requiresAuth: true)
        )
        .requireResult()
        let imageIds = dto.imageIds ?? []
        return CommunityPostDetail(
            postId: dto.postId,
            seriesId: dto.seriesId ?? 0,
            animeTitle: dto.animeTitle ?? "애니메이션",
            authorName: dto.nickname ?? "익명",
            authorImageURL: profileImageURL(dto.profileImageUrl),
            date: dto.createdAt ?? "",
            isSpoiler: dto.isSpoiler ?? false,
            imageIds: imageIds,
            imageURLs: imageIds.map(imageURL(id:)),
            title: dto.title ?? "",
            body: dto.content ?? "",
            viewCount: dto.viewCount ?? 0,
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0,
            isLiked: dto.likedByCurrentUser ?? false,
            isMine: dto.isMine ?? false
        )
    }

    public func comments(postId: Int, lastId: Int?) async throws(TransportError)
        -> CommunityCommentPage
    {
        let response = try await client.send(Self.commentsEndpoint(postId: postId, lastId: lastId))
        return CommunityCommentPage(
            comments: (response.result?.comments ?? []).map(comment),
            lastId: response.result?.cursor?.lastId
        )
    }

    static func commentsEndpoint(postId: Int, lastId: Int?) -> Endpoint<CommentsResult> {
        let parameters: [String: String?] = ["lastId": lastId.map(String.init), "size": "20"]
        return Endpoint(
            method: .get,
            path: "api/community/posts/\(postId)/comments",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }

    private func comment(_ dto: CommentsResult.Comment) -> CommunityComment {
        return CommunityComment(
            id: dto.commentId,
            authorName: dto.nickname ?? "익명",
            authorImageURL: profileImageURL(dto.profileImageUrl),
            date: dto.createdAt ?? "",
            content: dto.isDeleted == true ? "삭제된 댓글입니다." : (dto.content ?? ""),
            likeCount: dto.likeCount ?? 0,
            isLiked: dto.likedByCurrentUser ?? false,
            isMine: dto.isMine ?? false,
            replies: (dto.replies ?? []).map(comment)
        )
    }

    public func setPostLike(id: Int, liked: Bool) async throws(TransportError) {
        try await sendIgnoringResult(liked ? .post : .delete, "api/community/posts/\(id)/like")
    }

    public func setCommentLike(id: Int, liked: Bool) async throws(TransportError) {
        try await sendIgnoringResult(liked ? .post : .delete, "api/community/comments/\(id)/like")
    }

    public func createComment(postId: Int, content: String, parentCommentId: Int?)
        async throws(TransportError)
    {
        try await sendIgnoringResult(
            .post, "api/community/posts/\(postId)/comments",
            body: .json(CommentBody(content: content, parentCommentId: parentCommentId)))
    }

    public func updateComment(id: Int, content: String) async throws(TransportError) {
        try await sendIgnoringResult(
            .patch, "api/community/comments/\(id)",
            body: .json(CommentBody(content: content, parentCommentId: nil)))
    }

    public func deletePost(id: Int) async throws(TransportError) {
        try await sendIgnoringResult(.delete, "api/community/posts/\(id)")
    }

    public func deleteComment(id: Int) async throws(TransportError) {
        try await sendIgnoringResult(.delete, "api/community/comments/\(id)")
    }

    public func report(target: ReportTarget, targetId: Int, category: ReportCategory)
        async throws(TransportError)
    {
        try await sendIgnoringResult(
            .post, "api/community/reports",
            body: .json(
                ReportBody(
                    targetType: target.rawValue, targetId: targetId,
                    reportCategory: category.rawValue)))
    }

    /// 레거시는 HTTP 상태만 보고(`.validate()`) 본문 code는 보지 않는다
    private func sendIgnoringResult(_ method: HTTPMethod, _ path: String, body: RequestBody = .none)
        async throws(TransportError)
    {
        let _: ServerResponse<EmptyResult> = try await client.send(
            Self.endpoint(method, path, body: body))
    }

    static func endpoint(_ method: HTTPMethod, _ path: String, body: RequestBody = .none)
        -> Endpoint<EmptyResult>
    {
        return Endpoint(method: method, path: path, body: body, requiresAuth: true)
    }

    public func board(animeId: Int) async throws(TransportError) -> AnimeBoard? {
        let response = try await client.send(
            Endpoint<BoardResult>(
                method: .get, path: "api/community/boards/by-anime/\(animeId)", requiresAuth: true))
        return response.result.map {
            AnimeBoard(
                seriesId: $0.seriesId, hasBoard: $0.hasBoard, title: $0.title,
                coverImageUrl: $0.coverImageUrl,
                genres: $0.genres?.compactMap(\.name))
        }
    }

    public func imageURL(id: Int) -> URL {
        return imageBaseURL.appending(path: "api/image/\(id)")
    }

    public func uploadPostImage(jpeg: Data, fileName: String) async throws(TransportError) -> Int? {
        let response = try await client.send(Self.uploadEndpoint(jpeg: jpeg, fileName: fileName))
        return response.result?.imageId
    }

    /// 레거시 `CommunityAPIService.uploadPostImage`
    static func uploadEndpoint(jpeg: Data, fileName: String) -> Endpoint<UploadResult> {
        var form = MultipartForm()
        form.addFile(name: "postImageFile", fileName: fileName, mimeType: "image/jpeg", data: jpeg)
        return Endpoint(
            method: .post, path: "api/image/community-post-image", body: .multipart(form),
            requiresAuth: true)
    }

    public func createPost(seriesId: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return Self.outcome(try await client.send(Self.createEndpoint(seriesId: seriesId, draft)))
    }

    public func updatePost(id: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return Self.outcome(try await client.send(Self.updateEndpoint(id: id, draft)))
    }

    static func createEndpoint(seriesId: Int, _ draft: PostDraft) -> Endpoint<EmptyResult> {
        let body = CreateBody(
            seriesId: seriesId, title: draft.title, content: draft.content,
            isSpoiler: draft.isSpoiler, imageIds: draft.imageIds.isEmpty ? nil : draft.imageIds)
        return Endpoint(
            method: .post, path: "api/community/posts", body: .json(body), requiresAuth: true)
    }

    static func updateEndpoint(id: Int, _ draft: PostDraft) -> Endpoint<EmptyResult> {
        let body = UpdateBody(
            title: draft.title, content: draft.content, isSpoiler: draft.isSpoiler,
            imageIds: draft.imageIds)
        return Endpoint(
            method: .patch, path: "api/community/posts/\(id)", body: .json(body), requiresAuth: true
        )
    }

    private static func outcome(_ response: ServerResponse<EmptyResult>) -> PostSaveOutcome {
        return response.code == 200 ? .saved : .rejected(message: response.errorValue)
    }

    public func exploreBoards(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) async throws(TransportError) -> CommunityBoardPage {
        let response = try await client.send(
            Self.exploreBoardsEndpoint(
                sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId))
        let result = response.result
        return CommunityBoardPage(
            boards: (result?.boards ?? []).map {
                CommunityBoard(
                    seriesId: $0.seriesId, title: $0.title, coverImageUrl: $0.coverImageUrl,
                    genres: ($0.genres ?? []).compactMap(\.name))
            },
            lastId: result?.cursor?.lastId,
            lastValue: result?.cursor?.lastValue
        )
    }

    static func exploreBoardsEndpoint(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) -> Endpoint<BoardsResult> {
        let parameters: [String: String?] = [
            "sort": sort, "keyword": keyword, "lastValue": lastValue,
            "lastId": lastId.map(String.init),
            "size": "20",
        ]
        return Endpoint(
            method: .get,
            path: "api/community/explore/boards",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

/// 레거시 `CommunityBoardPage`
struct BoardsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
        let lastValue: String?
    }

    struct Genre: Decodable, Sendable {
        let name: String?
    }

    struct Board: Decodable, Sendable {
        let seriesId: Int
        let title: String?
        let coverImageUrl: String?
        let genres: [Genre]?
    }

    let cursor: Cursor?
    let boards: [Board]?
}

struct UploadResult: Decodable, Sendable {
    let imageId: Int?
}

/// 레거시 `CommunityPostRequest`. imageIds가 nil이면 키를 빼고 보낸다
struct CreateBody: Encodable, Sendable {
    let seriesId: Int
    let title: String
    let content: String
    let isSpoiler: Bool
    let imageIds: [Int]?
}

/// 레거시 `CommunityPostUpdateRequest`
struct UpdateBody: Encodable, Sendable {
    let title: String
    let content: String
    let isSpoiler: Bool
    let imageIds: [Int]
}

/// 레거시 `CommunityPostPage`
struct PostsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
        let lastValue: String?
    }

    struct Post: Decodable, Sendable {
        let postId: Int
        let title: String?
        let content: String?
        let thumbnailImageId: Int?
        let imageCount: Int?
        let isSpoiler: Bool?
        let likeCount: Int?
        let commentCount: Int?
        let createdAt: String?
        let nickname: String?
        let profileImageUrl: String?
    }

    let cursor: Cursor?
    let posts: [Post]?
}

/// 레거시 `CommunityPostDetailDTO`
struct DetailResult: Decodable, Sendable {
    let postId: Int
    let seriesId: Int?
    let animeTitle: String?
    let title: String?
    let content: String?
    let imageIds: [Int]?
    let isSpoiler: Bool?
    let viewCount: Int?
    let likeCount: Int?
    let commentCount: Int?
    let createdAt: String?
    let nickname: String?
    let profileImageUrl: String?
    let isMine: Bool?
    let likedByCurrentUser: Bool?
}

/// 레거시 `CommunityCommentPage`
struct CommentsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Comment: Decodable, Sendable {
        let commentId: Int
        let content: String?
        let nickname: String?
        let profileImageUrl: String?
        let likeCount: Int?
        let createdAt: String?
        let isDeleted: Bool?
        let isMine: Bool?
        let likedByCurrentUser: Bool?
        let replies: [Comment]?
    }

    let cursor: Cursor?
    let comments: [Comment]?
}

/// 레거시 `CommunityCommentRequest`. parentCommentId가 nil이면 키를 뺀다
struct CommentBody: Encodable, Sendable {
    let content: String
    let parentCommentId: Int?
}

/// 레거시 `CommunityReportRequest`
struct ReportBody: Encodable, Sendable {
    let targetType: String
    let targetId: Int
    let reportCategory: String
}

/// 레거시 `CommunityBoardByAnime`
struct BoardResult: Decodable, Sendable {
    struct Genre: Decodable, Sendable {
        let name: String?
    }

    let seriesId: Int?
    let hasBoard: Bool?
    let title: String?
    let coverImageUrl: String?
    let genres: [Genre]?
}
