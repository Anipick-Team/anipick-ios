import ClientCore

/// 상세 목록의 작품 한 칸 (레거시 `Anime`·`SeriesAnime`). 서버가 비워 보낼 수 있는 값은 모두 선택값이다
public struct DetailAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?

    public init(animeId: Int?, title: String?, coverImageUrl: String?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
    }
}

/// 관련 작품 한 페이지 (레거시 `SeriesAnimeResult`)
public struct SeriesPage: Equatable, Sendable {
    public let animes: [DetailAnime]
    /// 전체 개수
    public let count: Int
    public let lastId: Int?

    public init(animes: [DetailAnime], count: Int, lastId: Int?) {
        self.animes = animes
        self.count = count
        self.lastId = lastId
    }
}

/// 함께 볼만한 작품 한 페이지 (레거시 `RecommendationResult`)
public struct AnimeRecommendationPage: Equatable, Sendable {
    public let animes: [DetailAnime]
    public let referenceAnimeTitle: String?
    public let lastId: Int?

    public init(animes: [DetailAnime], referenceAnimeTitle: String?, lastId: Int?) {
        self.animes = animes
        self.referenceAnimeTitle = referenceAnimeTitle
        self.lastId = lastId
    }
}

/// 제작사 작품 한 칸 (레거시 `AnimeWithSeasonYear`). 방영 연도는 문자열이다
public struct StudioAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let seasonYear: String

    public init(animeId: Int?, title: String?, coverImageUrl: String?, seasonYear: String) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.seasonYear = seasonYear
    }
}

/// 제작사 상세 한 페이지 (레거시 `StudioDetailResult`)
public struct StudioPage: Equatable, Sendable {
    public let studioName: String
    public let animes: [StudioAnime]
    public let lastId: Int?
    public let lastValue: String?

    public init(studioName: String, animes: [StudioAnime], lastId: Int?, lastValue: String?) {
        self.studioName = studioName
        self.animes = animes
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

/// 캐릭터나 성우 한 명 (레거시 `AnimeCharacter`·`VoiceActor`)
public struct CastPerson: Hashable, Sendable {
    public let id: Int
    public let name: String
    public let imageUrl: String?

    public init(id: Int, name: String, imageUrl: String?) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
    }
}

/// 캐릭터와 성우 한 쌍 (레거시 `CharacterAndVoiceActorInfo`)
public struct CastMember: Hashable, Sendable {
    public let character: CastPerson?
    public let voiceActor: CastPerson?

    public init(character: CastPerson?, voiceActor: CastPerson?) {
        self.character = character
        self.voiceActor = voiceActor
    }
}

/// 성우가 맡은 배역 하나 (레거시 `PersonWork`)
public struct PersonWork: Hashable, Sendable {
    public let animeId: Int
    public let animeTitle: String
    public let characterId: Int
    public let characterName: String
    public let characterImageUrl: String?

    public init(
        animeId: Int, animeTitle: String, characterId: Int, characterName: String,
        characterImageUrl: String?
    ) {
        self.animeId = animeId
        self.animeTitle = animeTitle
        self.characterId = characterId
        self.characterName = characterName
        self.characterImageUrl = characterImageUrl
    }
}

/// 성우 상세 한 페이지 (레거시 `PersonDetailResult`)
public struct PersonPage: Equatable, Sendable {
    public let name: String
    public let profileImageUrl: String?
    public let isLiked: Bool
    /// 참여 작품 전체 개수
    public let count: Int
    public let lastId: Int
    public let works: [PersonWork]

    public init(
        name: String, profileImageUrl: String?, isLiked: Bool, count: Int, lastId: Int,
        works: [PersonWork]
    ) {
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.isLiked = isLiked
        self.count = count
        self.lastId = lastId
        self.works = works
    }
}

/// 애니 상세 정보 (레거시 `AnimeDetail`). animeId 말고는 모두 선택값이다
public struct AnimeInfo: Equatable, Sendable {
    public struct Studio: Hashable, Sendable {
        public let studioId: Int?
        public let name: String?

        public init(studioId: Int?, name: String?) {
            self.studioId = studioId
            self.name = name
        }
    }

    public let animeId: Int
    public let title: String?
    public let coverImageUrl: String?
    public let bannerImageUrl: String?
    public let description: String?
    public let averageRating: String?
    public let isLiked: Bool?
    /// WATCHLIST·WATCHING·FINISHED 또는 nil
    public let watchStatus: String?
    public let type: String?
    public let reviewCount: Int?
    public let genres: [String]?
    public let episode: Int?
    public let airDate: String?
    public let status: String?
    public let age: String?
    public let studios: [Studio]?

    public init(
        animeId: Int, title: String?, coverImageUrl: String?, bannerImageUrl: String?,
        description: String?,
        averageRating: String?, isLiked: Bool?, watchStatus: String?, type: String?,
        reviewCount: Int?,
        genres: [String]?, episode: Int?, airDate: String?, status: String?, age: String?,
        studios: [Studio]?
    ) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.bannerImageUrl = bannerImageUrl
        self.description = description
        self.averageRating = averageRating
        self.isLiked = isLiked
        self.watchStatus = watchStatus
        self.type = type
        self.reviewCount = reviewCount
        self.genres = genres
        self.episode = episode
        self.airDate = airDate
        self.status = status
        self.age = age
        self.studios = studios
    }
}

public protocol DetailClient: Sendable {
    /// 관련 작품 (`GET api/animes/{id}/series`, size=10). 결과가 없으면 nil
    func series(animeId: Int, lastId: Int?) async throws(TransportError) -> SeriesPage?
    /// 함께 볼만한 작품 (`GET api/animes/{id}/recommendations`, size=10). 결과나 목록이 없으면 nil
    func recommendations(animeId: Int, lastId: Int?) async throws(TransportError)
        -> AnimeRecommendationPage?
    /// 제작사 작품 (`GET api/studios/{id}/animes`, size=20). 이름·커서·목록은 필수 값 (없으면 `.decoding`)
    func studio(id: Int, lastId: Int?, lastValue: String?) async throws(TransportError)
        -> StudioPage
    /// 캐릭터·성우진 첫 20명 (`GET api/animes/{id}/characters`). 필수 값이 없으면 `.decoding`
    func characters(animeId: Int) async throws(TransportError) -> [CastMember]
    /// 성우 상세 (`GET api/person/{id}`, lastId·size=20). 모든 값이 필수 (없으면 `.decoding`)
    func person(id: Int, lastId: Int?) async throws(TransportError) -> PersonPage
    /// 인물 좋아요 (`POST`·`DELETE api/persons/{id}/like`). 응답은 보지 않는다
    func setPersonLike(id: Int, liked: Bool) async throws(TransportError)
    /// 애니 상세 (`GET api/animes/{id}/detail/info`). 결과가 없으면 `.decoding`
    func animeInfo(id: Int) async throws(TransportError) -> AnimeInfo
    /// 상세의 캐스트 (`GET api/animes/{id}/detail/actor`)
    func detailCast(animeId: Int) async throws(TransportError) -> [CastMember]
    /// 상세의 관련 작품 (`GET api/animes/{id}/detail/series`)
    func detailSeries(animeId: Int) async throws(TransportError) -> [DetailAnime]
    /// 상세의 함께 볼만한 작품 (`GET api/animes/{id}/detail/recommendation`)
    func detailRecommendations(animeId: Int) async throws(TransportError) -> [DetailAnime]
    /// 애니 좋아요 (`POST api/animes/{id}/like` JSON {animeId}) / 취소 (`DELETE`).
    /// 레거시처럼 HTTP 상태를 보지 않고 본문을 읽으면 성공이다
    func setAnimeLike(id: Int, liked: Bool) async throws(TransportError)
    /// 볼 애니·보는 중·다 본 애니 (`POST api/users/{id}/status` JSON {status}). 본문 code를 돌려준다 (128: 이미 상태가 있음)
    func setWatchStatus(animeId: Int, status: String) async throws(TransportError) -> Int
    /// 시청 상태 지우기 (`DELETE api/users/{id}/status`)
    func deleteWatchStatus(animeId: Int) async throws(TransportError)
}
