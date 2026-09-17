import Alamofire
import Foundation

enum CommunityAPI: URLRequestConvertible {
    case boardByAnime(animeId: Int)
    case posts(seriesId: Int, sort: String = "latest", lastValue: String?, lastId: Int?, size: Int = 20)
    case createPost(CommunityPostRequest)
    case postDetail(postId: Int)
    case updatePost(postId: Int, CommunityPostRequest)
    case deletePost(postId: Int)
    case likePost(postId: Int), unlikePost(postId: Int)
    case comments(postId: Int, lastId: Int?, size: Int = 20)
    case createComment(postId: Int, CommunityCommentRequest)
    case updateComment(commentId: Int, CommunityCommentRequest)
    case deleteComment(commentId: Int)
    case likeComment(commentId: Int), unlikeComment(commentId: Int)
    case report(CommunityReportRequest)
    case exploreBoards(sort: String = "popular", keyword: String?, lastValue: String?, lastId: Int?, size: Int = 20)
    case myPosts(lastId: Int?, size: Int = 20)
    case myComments(lastId: Int?, size: Int = 20)

    var path: String {
        switch self {
        case let .boardByAnime(animeId): return "api/community/boards/by-anime/\(animeId)"
        case let .posts(seriesId, _, _, _, _): return "api/community/boards/\(seriesId)/posts"
        case .createPost: return "api/community/posts"
        case let .postDetail(postId), let .updatePost(postId, _), let .deletePost(postId), let .likePost(postId), let .unlikePost(postId): return "api/community/posts/\(postId)" + (self.isPostAction ? "/like" : "")
        case let .comments(postId, _, _), let .createComment(postId, _): return "api/community/posts/\(postId)/comments"
        case let .updateComment(commentId, _), let .deleteComment(commentId), let .likeComment(commentId), let .unlikeComment(commentId): return "api/community/comments/\(commentId)" + (self.isCommentAction ? "/like" : "")
        case .report: return "api/community/reports"
        case .exploreBoards: return "api/community/explore/boards"
        case .myPosts: return "api/mypage/community/posts"
        case .myComments: return "api/mypage/community/comments"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .boardByAnime, .posts, .postDetail, .comments, .exploreBoards, .myPosts, .myComments: return .get
        case .createPost, .createComment, .likePost, .likeComment, .report: return .post
        case .updatePost, .updateComment: return .patch
        case .deletePost, .deleteComment, .unlikePost, .unlikeComment: return .delete
        }
    }

    private var isPostAction: Bool {
        if case .likePost = self { return true }; if case .unlikePost = self { return true }; return false
    }

    private var isCommentAction: Bool {
        if case .likeComment = self { return true }; if case .unlikeComment = self { return true }; return false
    }

    var parameters: Parameters? {
        switch self {
        case let .posts(_, sort, lastValue, lastId, size): return compact(["sort": sort, "lastValue": lastValue, "lastId": lastId, "size": size])
        case let .comments(_, lastId, size): return compact(["lastId": lastId, "size": size])
        case let .exploreBoards(sort, keyword, lastValue, lastId, size): return compact(["sort": sort, "keyword": keyword, "lastValue": lastValue, "lastId": lastId, "size": size])
        case let .myPosts(lastId, size), let .myComments(lastId, size): return compact(["lastId": lastId, "size": size])
        default: return nil
        }
    }

    private func compact(_ values: [String: Any?]) -> Parameters { values.compactMapValues { $0 } }

    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: try NetworkManager.baseUrl.asURL().appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(UserDefaultsManager.shared.getAccessToken())", forHTTPHeaderField: "Authorization")

        switch self {
        case let .createPost(body), let .updatePost(_, body): request = try JSONParameterEncoder.default.encode(body, into: request)
        case let .createComment(_, body), let .updateComment(_, body): request = try JSONParameterEncoder.default.encode(body, into: request)
        case let .report(body): request = try JSONParameterEncoder.default.encode(body, into: request)
        default: request = try URLEncoding.default.encode(request, with: parameters)
        }
        return request
    }
}
