import Foundation
import MetadataClientInterface
import Storage
import Testing

@testable import MetadataClientLive

@Suite("LiveMetadataClient")
struct LiveMetadataClientTests {
    private let defaults = UserDefaults(suiteName: "metadata-\(UUID().uuidString)")!

    @Test("레거시가 JSON Data로 저장한 장르와 [Int]로 저장한 연도를 읽는다")
    func readsLegacyFormat() throws {
        // 레거시 UserDefaultsManager.setMetaDataForGenres / setMetaDataForSeasonYear와 같은 형식
        let legacyGenres = #"[{"id":1,"name":"액션"},{"id":7,"name":"SF"}]"#
        defaults.set(Data(legacyGenres.utf8), forKey: "animeGenres")
        defaults.set([2026, 2025], forKey: "seasonYear")

        let client = LiveMetadataClient(preferences: Preferences(defaults: defaults))

        #expect(client.cachedGenres() == [Genre(id: 1, name: "액션"), Genre(id: 7, name: "SF")])
        #expect(client.cachedSeasonYears() == [2026, 2025])
    }

    @Test("저장된 값이 없으면 빈 목록")
    func emptyWhenMissing() {
        let client = LiveMetadataClient(preferences: Preferences(defaults: defaults))

        #expect(client.cachedGenres().isEmpty)
        #expect(client.cachedSeasonYears().isEmpty)
    }
}
