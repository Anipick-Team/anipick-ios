import Foundation
import Testing

import Storage

@Suite("Preferences")
final class PreferencesTests {
    private let suiteName = "com.moana.StorageTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let preferences: Preferences

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        preferences = Preferences(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("저장된 값이 없으면 기본값을 돌려준다")
    func returnsDefaultValueWhenMissing() {
        #expect(preferences.value(for: PreferenceKey("nickname", defaultValue: "--")) == "--")
        #expect(preferences.value(for: PreferenceKey("imageId", defaultValue: 0)) == 0)
    }

    @Test("property list 값을 저장하고 읽는다")
    func storesPropertyListValues() {
        let keyword = PreferenceKey("homeRecentKeyword", defaultValue: [String]())
        let notice = PreferenceKey("hasSeenServerRecoveryNotice", defaultValue: false)
        let imageId = PreferenceKey("imageId", defaultValue: 0)

        preferences.set(["원피스", "나루토"], for: keyword)
        preferences.set(true, for: notice)
        preferences.set(42, for: imageId)

        #expect(preferences.value(for: keyword) == ["원피스", "나루토"])
        #expect(preferences.value(for: notice))
        #expect(preferences.value(for: imageId) == 42)
    }

    @Test("레거시가 UserDefaults에 직접 저장한 값을 같은 키 이름으로 읽는다")
    func readsValuesWrittenByLegacy() {
        defaults.set("애니픽", forKey: "nickname")
        defaults.set([2024, 2025], forKey: "seasonYear")
        defaults.set(7, forKey: "lastVisitedAnime")

        let nickname = PreferenceKey("nickname", defaultValue: "--")
        let seasonYear = PreferenceKey("seasonYear", defaultValue: [Int]())
        let lastVisitedAnime = PreferenceKey("lastVisitedAnime", defaultValue: 0)

        #expect(preferences.value(for: nickname) == "애니픽")
        #expect(preferences.value(for: seasonYear) == [2024, 2025])
        #expect(preferences.value(for: lastVisitedAnime) == 7)
    }

    @Test("저장된 값의 타입이 다르면 기본값을 돌려준다")
    func returnsDefaultValueOnTypeMismatch() {
        defaults.set("not a number", forKey: "imageId")

        #expect(preferences.value(for: PreferenceKey("imageId", defaultValue: 0)) == 0)
    }

    @Test("Codable 값을 JSON으로 저장하고 읽는다")
    func storesCodableValue() throws {
        struct Genre: Codable, Equatable, Sendable {
            let id: Int
            let name: String
        }
        let key = PreferenceKey("animeGenres", defaultValue: [Genre]())

        try preferences.setCodable([Genre(id: 1, name: "액션")], for: key)

        #expect(preferences.codableValue(for: key) == [Genre(id: 1, name: "액션")])
    }

    @Test("Codable 값을 디코딩할 수 없으면 기본값을 돌려준다")
    func returnsDefaultValueWhenDecodingFails() {
        defaults.set(Data("broken".utf8), forKey: "animeGenres")

        let key = PreferenceKey("animeGenres", defaultValue: [Int]())

        #expect(preferences.codableValue(for: key) == [])
    }

    @Test("삭제하면 기본값을 돌려준다")
    func removesValue() {
        let key = PreferenceKey("email", defaultValue: "")
        preferences.set("a@b.com", for: key)

        preferences.removeValue(for: key)

        #expect(preferences.value(for: key) == "")
    }
}
