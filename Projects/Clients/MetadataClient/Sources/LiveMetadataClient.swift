import ClientCore
import MetadataClientInterface
import Networking
import Storage

public struct LiveMetadataClient: MetadataClient {
    /// 레거시 `UserDefaultKey`와 같은 키
    static let genresKey = PreferenceKey<[Genre]>("animeGenres", defaultValue: [])
    static let seasonYearsKey = PreferenceKey<[Int]>("seasonYear", defaultValue: [])
    static let seasonsKey = PreferenceKey<[Genre]>("seasonQuater", defaultValue: [])
    static let typesKey = PreferenceKey<[String]>("animeType", defaultValue: [])

    private let preferences: Preferences
    private let client: HTTPClient?

    /// - Parameter client: `refresh()`가 쓰는 클라이언트. 없으면 저장값만 읽는다
    public init(preferences: Preferences = Preferences(), client: HTTPClient? = nil) {
        self.preferences = preferences
        self.client = client
    }

    /// 레거시 `fetchMataData`: 없는 값은 빈 목록으로 저장한다
    public func refresh() async {
        guard
            let client,
            let response = try? await client.send(
                Endpoint<MetadataResult>(
                    method: .get, path: "api/animes/meta-data-group", requiresAuth: true)),
            let result = response.result
        else {
            return
        }
        preferences.set(result.seasonYear ?? [], for: Self.seasonYearsKey)
        preferences.set(result.type ?? [], for: Self.typesKey)
        try? preferences.setCodable(result.genres ?? [], for: Self.genresKey)
        try? preferences.setCodable(result.season ?? [], for: Self.seasonsKey)
    }

    /// 레거시는 `[Genre]`를 JSON `Data`로 저장한다 (`UserDefaultsManager.setMetaDataForGenres`)
    public func cachedGenres() -> [Genre] {
        return preferences.codableValue(for: Self.genresKey)
    }

    public func cachedSeasonYears() -> [Int] {
        return preferences.value(for: Self.seasonYearsKey)
    }
}

/// 레거시 `MetaDataResult`. 분기도 {id,name} 모양이라 `Genre`로 읽는다
struct MetadataResult: Decodable, Sendable {
    let seasonYear: [Int]?
    let season: [Genre]?
    let genres: [Genre]?
    let type: [String]?
}
