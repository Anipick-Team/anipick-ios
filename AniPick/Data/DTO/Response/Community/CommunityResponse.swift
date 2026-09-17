import Foundation

struct CommunityImageUploadResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityImageUploadResult?
}

struct CommunityImageUploadResult: Decodable {
    let imageId: Int?
}

struct CommunityBoardByAnimeResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityBoard?
}

struct CommunityBoardsResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityBoardPage?
}

struct CommunityBoardPage: Decodable {
    let count: Int?
    let cursor: CommunityCursor?
    let boards: [CommunityBoard]?
}

struct CommunityBoard: Decodable, Identifiable, Hashable {
    let seriesId: Int
    let title: String?
    let coverImageUrl: String?
    let genres: [CommunityGenre]?

    var id: Int { seriesId }
}

struct CommunityGenre: Decodable, Hashable {
    let id: Int?
    let name: String?
}

struct CommunityPostsResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityPostPage?
}

struct CommunityPostPage: Decodable {
    let count: Int?
    let cursor: CommunityCursor?
    let posts: [CommunityPostDTO]?
}

struct CommunityCursor: Decodable {
    let sort: String?
    let lastId: Int?
    let lastValue: String?
}

struct CommunityPostDTO: Decodable, Identifiable, Hashable {
    let postId: Int
    let seriesId: Int?
    let animeTitle: String?
    let animeCoverImageUrl: String?
    let title: String?
    let content: String?
    let thumbnailImageId: Int?
    let isSpoiler: Bool?
    let viewCount: Int?
    let likeCount: Int?
    let commentCount: Int?
    let createdAt: String?
    let nickname: String?
    let profileImageUrl: String?
    let isMine: Bool?
    let likedByCurrentUser: Bool?

    var id: Int { postId }
}

struct CommunityPostDetailResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityPostDetailDTO?
}

struct CommunityPostDetailDTO: Decodable, Identifiable, Hashable {
    let postId: Int
    let seriesId: Int?
    let animeTitle: String?
    let animeCoverImageUrl: String?
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

    var id: Int { postId }
}

struct CommunityCommentsResponse: Decodable {
    let code: Int
    let value: String
    let result: CommunityCommentPage?
}

struct CommunityCommentPage: Decodable {
    let count: Int?
    let cursor: CommunityCursor?
    let comments: [CommunityCommentDTO]?
}

struct CommunityCommentDTO: Decodable, Identifiable, Hashable {
    let commentId: Int
    let parentCommentId: Int?
    let content: String?
    let nickname: String?
    let profileImageUrl: String?
    let likeCount: Int?
    let createdAt: String?
    let isEdited: Bool?
    let isDeleted: Bool?
    let isMine: Bool?
    let likedByCurrentUser: Bool?
    let replies: [CommunityCommentDTO]?

    var id: Int { commentId }
}

struct MyCommunityPostsResponse: Decodable {
    let code: Int
    let value: String
    let result: MyCommunityPostPage?
}

struct MyCommunityPostPage: Decodable {
    let count: Int?
    let cursor: MyCommunityCursor?
    let posts: [MyCommunityPost]?
}

struct MyCommunityCursor: Decodable {
    let lastId: Int?
}

struct MyCommunityPost: Decodable, Identifiable, Hashable {
    let postId: Int
    let seriesId: Int?
    let animeTitle: String?
    let animeCoverImageUrl: String?
    let title: String?
    let content: String?
    let thumbnailImageId: Int?
    let isSpoiler: Bool?
    let viewCount: Int?
    let likeCount: Int?
    let commentCount: Int?
    let createdAt: String?

    var id: Int { postId }
}

struct MyCommunityCommentsResponse: Decodable {
    let code: Int
    let value: String
    let result: MyCommunityCommentPage?
}

struct MyCommunityCommentPage: Decodable {
    let count: Int?
    let cursor: MyCommunityCursor?
    let comments: [MyCommunityComment]?
}

struct MyCommunityComment: Decodable, Identifiable, Hashable {
    let commentId: Int
    let postId: Int?
    let animeTitle: String?
    let animeCoverImageUrl: String?
    let postTitle: String?
    let content: String?
    let likeCount: Int?
    let createdAt: String?

    var id: Int { commentId }
}
