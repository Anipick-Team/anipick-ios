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
}

struct CommunityReportRequest: Encodable {
    let targetType: CommunityReportTarget
    let targetId: Int
    let reportCategory: CommunityReportCategory
}
