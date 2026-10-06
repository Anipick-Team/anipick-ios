import Foundation

struct CommunityPostRequest: Encodable {
    let seriesId: Int
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
