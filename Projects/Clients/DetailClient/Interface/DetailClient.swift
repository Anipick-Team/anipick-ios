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
}
