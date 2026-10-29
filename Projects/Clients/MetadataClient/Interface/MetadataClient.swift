/// 장르 (서버 메타데이터)
public struct Genre: Equatable, Hashable, Sendable, Codable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

/// 앱 시작 때 받아 이 기기에 저장해 둔 메타데이터. 받은 적이 없으면 빈 목록이다.
public protocol MetadataClient: Sendable {
    func cachedGenres() -> [Genre]
    /// 서버가 준 순서 그대로의 연도 목록
    func cachedSeasonYears() -> [Int]
    /// 작품 유형 (TV, OVA, MOVIE 등)
    func cachedTypes() -> [String]
    /// 서버에서 다시 받아 이 기기에 저장한다 (`GET api/animes/meta-data-group`). 실패하면 저장값을 그대로 둔다
    func refresh() async
}
