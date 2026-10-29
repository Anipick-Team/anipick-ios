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
