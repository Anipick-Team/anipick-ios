import ClientCore
import Foundation
import MyInfoClientInterface
import Networking
import Storage

public struct LiveMyInfoClient: MyInfoClient {
    /// 레거시 `UserDefaultKey.imageId`
    static let imageIdKey = PreferenceKey("imageId", defaultValue: 0)

    private let client: HTTPClient
    private let imageBaseURL: URL
    private let preferences: Preferences

    /// - Parameters:
    ///   - client: 인증 클라이언트
    ///   - imageBaseURL: 이미지 id를 주소로 바꿀 때 쓰는 서버 주소 (`{주소}api/image/{id}`)
    public init(client: HTTPClient, imageBaseURL: URL, preferences: Preferences = Preferences()) {
        self.client = client
        self.imageBaseURL = imageBaseURL
        self.preferences = preferences
    }

    public func profile() async throws(TransportError) -> MyProfile {
        let result = try await client.send(
            Endpoint<ProfileResult>(method: .get, path: "api/mypage", requiresAuth: true)
        )
        .requireResult()
        return MyProfile(
            profileImageUrl: result.profileImageUrl,
            watchCounts: result.watchCounts.map {
                MyProfile.WatchCounts(
                    watchList: $0.watchList, watching: $0.watching, finished: $0.finished)
            },
            likedAnimes: result.likedAnimes?.map(\.anime)
        )
    }

    public func profileImage(id: Int) async throws(TransportError) -> Data {
        return try await client.sendRaw(
            Endpoint(method: .get, path: "api/image/\(id)", requiresAuth: true))
    }

    /// 레거시는 `http://anipick.p-e.kr:8080`(HTTP, 다른 포트)으로 올렸다. 다른 요청과 같은 HTTPS 기본 주소를 쓴다 (이관 발견 버그 2026-10-18)
    public func uploadProfileImage(jpeg: Data) async throws(TransportError) -> Int {
        let result = try await client.send(Self.uploadEndpoint(jpeg: jpeg)).requireResult()
        preferences.set(result.imageId, for: Self.imageIdKey)
        return result.imageId
    }

    static func uploadEndpoint(jpeg: Data) -> Endpoint<UploadResult> {
        var form = MultipartForm()
        form.addFile(
            name: "profileImageFile", fileName: "profile.jpg", mimeType: "image/jpeg", data: jpeg)
        return Endpoint(
            method: .post, path: "api/image/profile-image", body: .multipart(form),
            requiresAuth: true)
    }

    public func myPosts(lastId: Int?) async throws(TransportError) -> ContentPage<MyPost> {
        let result = try await client.send(
            Self.endpoint(
                "api/mypage/community/posts", ["lastId": lastId.map(String.init), "size": "20"])
                as Endpoint<PostsResult>
        )
        .requireResult()
        return ContentPage(
            count: result.count,
            lastId: result.cursor?.lastId,
            items: (result.posts ?? []).map { $0.post(imageBaseURL: imageBaseURL) }
        )
    }

    public func myComments(lastId: Int?) async throws(TransportError) -> ContentPage<MyComment> {
        let result = try await client.send(
            Self.endpoint(
                "api/mypage/community/comments", ["lastId": lastId.map(String.init), "size": "20"])
                as Endpoint<CommentsResult>
        )
        .requireResult()
        return ContentPage(
            count: result.count,
            lastId: result.cursor?.lastId,
            items: (result.comments ?? []).map(\.comment)
        )
    }

    public func watchList(
        _ status: WatchStatus,
        lastId: Int?
    ) async throws(TransportError) -> MyPage<MyAnime> {
        let result = try await client.send(Self.watchListEndpoint(status, lastId: lastId))
            .requireResult()
        return MyPage(
            count: result.count,
            items: (result.animes ?? []).map(\.anime),
            lastId: result.cursor.lastId
        )
    }

    public func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime> {
        let result = try await client.send(Self.likedAnimesEndpoint(lastId: lastId)).requireResult()
        return MyPage(
            count: result.count,
            items: (result.animes ?? []).map(\.anime),
            lastId: result.cursor?.lastId
        )
    }

    public func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson> {
        let result = try await client.send(Self.likedPersonsEndpoint(lastId: lastId))
            .requireResult()
        return MyPage(
            count: result.count,
            items: result.persons.map(\.person),
            lastId: result.cursor.lastId
        )
    }

    public func ratedReviews(
        sort: RatedSort,
        lastId: Int?,
        lastLikeCount: Int?,
        lastRating: Double?
    ) async throws(TransportError) -> RatedPage {
        let result = try await client.send(
            Self.ratedReviewsEndpoint(
                sort: sort, lastId: lastId, lastLikeCount: lastLikeCount, lastRating: lastRating)
        )
        .requireResult()
        return RatedPage(
            count: result.count,
            lastId: result.cursor?.lastId,
            reviews: (result.reviews ?? []).map(\.review)
        )
    }

    /// 레거시 `MyInfoAPI.ratedAnimeList`: `lastRating`은 Double 그대로(예: "4.5"), `reviewOnly`는 늘 "false"
    static func ratedReviewsEndpoint(
        sort: RatedSort,
        lastId: Int?,
        lastLikeCount: Int?,
        lastRating: Double?
    ) -> Endpoint<RatedResult> {
        return endpoint(
            "api/mypage/animes/rated",
            [
                "lastId": lastId.map(String.init), "lastLikeCount": lastLikeCount.map(String.init),
                "lastRating": lastRating.map { String($0) }, "size": "20", "sort": sort.rawValue,
                "reviewOnly": "false",
            ]
        )
    }

    /// 레거시 경로: 상태마다 다른 경로에 같은 `status`를 함께 보낸다
    static func watchListEndpoint(_ status: WatchStatus, lastId: Int?) -> Endpoint<WatchListResult>
    {
        let path: String
        switch status {
        case .watchList:
            path = "api/mypage/animes/watchlist"
        case .watching:
            path = "api/mypage/animes/watching"
        case .finished:
            path = "api/mypage/animes/finished"
        }
        return endpoint(
            path, ["status": status.rawValue, "lastId": lastId.map(String.init), "size": "20"])
    }

    static func likedAnimesEndpoint(lastId: Int?) -> Endpoint<LikedAnimesResult> {
        return endpoint(
            "api/mypage/animes/like", ["lastId": lastId.map(String.init), "size": "20"])
    }

    static func likedPersonsEndpoint(lastId: Int?) -> Endpoint<LikedPersonsResult> {
        return endpoint(
            "api/mypage/persons/like", ["lastId": lastId.map(String.init), "size": "30"])
    }

    /// 값이 없는 파라미터는 빼고 이름순으로 (Alamofire `URLEncoding` 기본 동작)
    private static func endpoint<Result>(_ path: String, _ parameters: [String: String?])
        -> Endpoint<Result>
    {
        return Endpoint(
            method: .get,
            path: path,
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

struct AnimeDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let myRating: Double?

    var anime: MyAnime {
        return MyAnime(
            animeId: animeId, title: title, coverImageUrl: coverImageUrl, myRating: myRating)
    }
}

struct PersonDTO: Decodable, Sendable {
    let personId: Int?
    let name: String?
    let profileImageUrl: String?

    var person: MyPerson {
        return MyPerson(personId: personId, name: name, profileImageUrl: profileImageUrl)
    }
}

/// 레거시 `ToWatchListResult`: 커서는 반드시 온다
struct WatchListResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int
    }

    let count: Int
    let cursor: Cursor
    let animes: [AnimeDTO]?
}

/// 레거시 `MyInfoLikedAnimeResult`
struct LikedAnimesResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    let count: Int
    let cursor: Cursor?
    let animes: [AnimeDTO]?
}

/// 레거시 `LikedPersonListResult`
struct LikedPersonsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    let count: Int
    let cursor: Cursor
    let persons: [PersonDTO]
}

/// 레거시 `MyReviewListResult`: 모든 값이 선택값
struct RatedResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Review: Decodable, Sendable {
        let animeId: Int?
        let title: String?
        let coverImageUrl: String?
        let rating: Double?
        let reviewId: Int?
        let reviewContent: String?
        let createdAt: String?
        let likeCount: Int?

        var review: RatedReview {
            return RatedReview(
                animeId: animeId, title: title, coverImageUrl: coverImageUrl, rating: rating,
                reviewId: reviewId, reviewContent: reviewContent, createdAt: createdAt,
                likeCount: likeCount)
        }
    }

    let count: Int?
    let cursor: Cursor?
    let reviews: [Review]?
}

struct GenreDTO: Decodable, Sendable {
    let name: String?
}

/// 레거시 `MyCommunityPostPage`
struct PostsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Post: Decodable, Sendable {
        let postId: Int
        let animeTitle: String?
        let animeCoverImageUrl: String?
        let genres: [GenreDTO]?
        let title: String?
        let content: String?
        let thumbnailImageId: Int?
        let isSpoiler: Bool?
        let viewCount: Int?
        let likeCount: Int?
        let commentCount: Int?
        let createdAt: String?

        /// 레거시 `MyContentViewModel.imageURL(for:)`: `{서버 주소}api/image/{id}`
        func post(imageBaseURL: URL) -> MyPost {
            return MyPost(
                postId: postId, animeTitle: animeTitle, animeCoverImageUrl: animeCoverImageUrl,
                genre: genres?.first?.name, title: title, content: content,
                thumbnailURL: thumbnailImageId.map {
                    imageBaseURL.appending(path: "api/image/\($0)")
                },
                isSpoiler: isSpoiler, viewCount: viewCount, likeCount: likeCount,
                commentCount: commentCount, createdAt: createdAt)
        }
    }

    let count: Int?
    let cursor: Cursor?
    let posts: [Post]?
}

/// 레거시 `MyCommunityCommentPage`
struct CommentsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Comment: Decodable, Sendable {
        let commentId: Int
        let postId: Int?
        let animeTitle: String?
        let animeCoverImageUrl: String?
        let genres: [GenreDTO]?
        let postTitle: String?
        let content: String?
        let likeCount: Int?
        let createdAt: String?

        var comment: MyComment {
            return MyComment(
                commentId: commentId, postId: postId, animeTitle: animeTitle,
                animeCoverImageUrl: animeCoverImageUrl, genre: genres?.first?.name,
                postTitle: postTitle, content: content, likeCount: likeCount, createdAt: createdAt)
        }
    }

    let count: Int?
    let cursor: Cursor?
    let comments: [Comment]?
}

/// 레거시 `UserProfile`
struct ProfileResult: Decodable, Sendable {
    struct Counts: Decodable, Sendable {
        let watchList: Int?
        let watching: Int?
        let finished: Int?
    }

    let profileImageUrl: String?
    let watchCounts: Counts?
    let likedAnimes: [AnimeDTO]?
}

/// 레거시 `ProfileImageID`
struct UploadResult: Decodable, Sendable {
    let imageId: Int
}
