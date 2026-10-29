import ClientCore

/// 볼·보는 중·다 본 애니 (서버 `status` 값)
public enum WatchStatus: String, CaseIterable, Sendable {
    case watchList = "WATCHLIST"
    case watching = "WATCHING"
    case finished = "FINISHED"
}

/// 목록의 애니 한 칸 (레거시 `ToWatchAnime`·`LikedAnime`)
public struct MyAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    /// 다 본 애니에서만 온다
    public let myRating: Double?

    public init(animeId: Int?, title: String?, coverImageUrl: String?, myRating: Double? = nil) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.myRating = myRating
    }
}

/// 좋아요한 인물 한 칸 (레거시 `LikedRatedPerson`)
public struct MyPerson: Hashable, Sendable {
    public let personId: Int?
    public let name: String?
    public let profileImageUrl: String?

    public init(personId: Int?, name: String?, profileImageUrl: String?) {
        self.personId = personId
        self.name = name
        self.profileImageUrl = profileImageUrl
    }
}

/// 한 페이지. `count`는 전체 개수
public struct MyPage<Item: Hashable & Sendable>: Equatable, Sendable {
    public let count: Int
    public let items: [Item]
    /// 다음 페이지 커서. 서버가 비워 보낼 수 있다
    public let lastId: Int?

    public init(count: Int, items: [Item], lastId: Int?) {
        self.count = count
        self.items = items
        self.lastId = lastId
    }
}

/// 마이페이지 목록 (레거시 `MyInfoAPI`)
public protocol MyInfoClient: Sendable {
    /// 20개씩
    func watchList(_ status: WatchStatus, lastId: Int?) async throws(TransportError) -> MyPage<
        MyAnime
    >
    /// 20개씩
    func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime>
    /// 30개씩
    func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson>
}
