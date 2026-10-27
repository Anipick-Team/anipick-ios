import Foundation

struct CommunityPostRequest: Encodable {
    let seriesId: Int
    let title: String
    let content: String
    let isSpoiler: Bool
    let imageIds: [Int]?
}

/// PATCH api/community/posts/{postId} 요청. 서버 PostUpdateRequest와 필드를 맞춘다.
/// (seriesId를 보내면 서버가 알 수 없는 필드로 400을 반환)
struct CommunityPostUpdateRequest: Encodable {
    let title: String
    let content: String
    let isSpoiler: Bool
    let imageIds: [Int]?
}

struct CommunityCommentRequest: Encodable {
    let content: String
    let parentCommentId: Int?
}

enum CommunityReportTarget: String, Encodable {
    case post = "POST"
    case comment = "COMMENT"
}

enum CommunityReportCategory: String, Encodable {
    case abuse = "ABUSE"
    case privacy = "PRIVACY"
    case spam = "SPAM"
    case illegal = "ILLEGAL"
    case etc = "ETC"

    var displayName: String {
        switch self {
        case .abuse: return "욕설/비하/혐오 표현"
        case .privacy: return "개인정보 노출"
        case .spam: return "도배/스팸/광고성 내용"
        case .illegal: return "불법/유해/부적절한 내용"
        case .etc: return "기타 운영정책 위반"
        }
    }
}

struct CommunityReportRequest: Encodable {
    let targetType: CommunityReportTarget
    let targetId: Int
    let reportCategory: CommunityReportCategory
}
