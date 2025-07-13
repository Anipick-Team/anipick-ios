import Foundation

// MARK: - Top-Level Response
struct LikedPersonListResponse: Codable {
    let code: Int
    let value: String
    let result: LikedPersonListResult
}

// MARK: - Result
struct LikedPersonListResult: Codable {
    let count: Int
    let cursor: LikedPersonCursor
    let persons: [LikedPerson]
}

// MARK: - Cursor
struct LikedPersonCursor: Codable {
    let lastId: Int
}

// MARK: - Liked Person
struct LikedPerson: Codable, Identifiable {
    let personId: Int
    let userLikedVoiceActorId: Int
    let name: String
    let profileImageUrl: String

    var id: Int { personId } // ForEach 등을 위해 Identifiable 적용
}
