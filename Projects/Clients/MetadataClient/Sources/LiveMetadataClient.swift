import MetadataClientInterface
import Storage

public struct LiveMetadataClient: MetadataClient {
    /// 레거시 `UserDefaultKey`와 같은 키
    static let genresKey = PreferenceKey<[Genre]>("animeGenres", defaultValue: [])
    static let seasonYearsKey = PreferenceKey<[Int]>("seasonYear", defaultValue: [])

    private let preferences: Preferences

    public init(preferences: Preferences = Preferences()) {
        self.preferences = preferences
    }

    /// 레거시는 `[Genre]`를 JSON `Data`로 저장한다 (`UserDefaultsManager.setMetaDataForGenres`)
    public func cachedGenres() -> [Genre] {
        return preferences.codableValue(for: Self.genresKey)
    }

    public func cachedSeasonYears() -> [Int] {
        return preferences.value(for: Self.seasonYearsKey)
    }
}
