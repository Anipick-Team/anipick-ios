import Foundation

// MARK: - Top-Level Response
struct AnimeListResponse: Codable {
    let code: Int
    let value: String
    let result: [AnimeItem]
}

// MARK: - Anime Item
struct AnimeItem: Codable, Identifiable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let airDate: String

    var id: Int { animeId }
}
