import Alamofire
import Foundation

final class CommunityAPIService {
    static let shared = CommunityAPIService()

    func uploadPostImage(data: Data, fileName: String, mimeType: String) async throws -> CommunityImageUploadResponse {
        try await NetworkManager.upload(
            data: data,
            path: "api/image/community-post-image",
            fieldName: "postImageFile",
            fileName: fileName,
            mimeType: mimeType
        )
    }

    func boardByAnime(animeId: Int) async throws -> CommunityBoardByAnimeResponse { try await request(.boardByAnime(animeId: animeId)) }
    func posts(seriesId: Int, sort: String = "latest", lastValue: String? = nil, lastId: Int? = nil, size: Int = 20) async throws -> CommunityPostsResponse { try await request(.posts(seriesId: seriesId, sort: sort, lastValue: lastValue, lastId: lastId, size: size)) }
    func createPost(_ body: CommunityPostRequest) async throws -> BaseResponse { try await request(.createPost(body)) }
    func postDetail(postId: Int) async throws -> CommunityPostDetailResponse { try await request(.postDetail(postId: postId)) }
    func updatePost(postId: Int, body: CommunityPostRequest) async throws -> BaseResponse { try await request(.updatePost(postId: postId, body)) }
    func deletePost(postId: Int) async throws -> BaseResponse { try await request(.deletePost(postId: postId)) }
    func likePost(postId: Int) async throws -> BaseResponse { try await request(.likePost(postId: postId)) }
    func unlikePost(postId: Int) async throws -> BaseResponse { try await request(.unlikePost(postId: postId)) }
    func comments(postId: Int, lastId: Int? = nil, size: Int = 20) async throws -> CommunityCommentsResponse { try await request(.comments(postId: postId, lastId: lastId, size: size)) }
    func createComment(postId: Int, body: CommunityCommentRequest) async throws -> BaseResponse { try await request(.createComment(postId: postId, body)) }
    func updateComment(commentId: Int, body: CommunityCommentRequest) async throws -> BaseResponse { try await request(.updateComment(commentId: commentId, body)) }
    func deleteComment(commentId: Int) async throws -> BaseResponse { try await request(.deleteComment(commentId: commentId)) }
    func likeComment(commentId: Int) async throws -> BaseResponse { try await request(.likeComment(commentId: commentId)) }
    func unlikeComment(commentId: Int) async throws -> BaseResponse { try await request(.unlikeComment(commentId: commentId)) }
    func report(_ body: CommunityReportRequest) async throws -> BaseResponse { try await request(.report(body)) }
    func exploreBoards(sort: String = "popular", keyword: String? = nil, lastValue: String? = nil, lastId: Int? = nil, size: Int = 20) async throws -> CommunityBoardsResponse { try await request(.exploreBoards(sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId, size: size)) }
    func myPosts(lastId: Int? = nil, size: Int = 20) async throws -> MyCommunityPostsResponse { try await request(.myPosts(lastId: lastId, size: size)) }
    func myComments(lastId: Int? = nil, size: Int = 20) async throws -> MyCommunityCommentsResponse { try await request(.myComments(lastId: lastId, size: size)) }

    private func request<T: Decodable>(_ api: CommunityAPI) async throws -> T {
        do {
            let request = try api.asURLRequest()
            DLog("커뮤니티 API 요청 - \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
            let response: T = try await NetworkManager.request(api)
            DLog("커뮤니티 API 응답 성공 - \(request.url?.path ?? "")")
            return response
        } catch {
            DLog("커뮤니티 API 응답 실패 - \(error)")
            throw error
        }
    }
}
