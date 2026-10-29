import MetadataClientInterface

public struct MockMetadataClient: MetadataClient {
    public var genres: [Genre]
    public var seasonYears: [Int]

    public init(
        genres: [Genre] = [
            Genre(id: 1, name: "액션"), Genre(id: 2, name: "코미디"), Genre(id: 3, name: "드라마"),
            Genre(id: 4, name: "판타지"), Genre(id: 5, name: "로맨스"),
        ],
        seasonYears: [Int] = [2026, 2025, 2024]
    ) {
        self.genres = genres
        self.seasonYears = seasonYears
    }

    public func cachedGenres() -> [Genre] {
        return genres
    }

    public func cachedSeasonYears() -> [Int] {
        return seasonYears
    }
}
