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

    @Test("PS2. refresh: api/animes/meta-data-group을 받아 레거시 키·형식으로 저장한다")
    func refreshes() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"seasonYear":[2026],"season":[{"id":1,"name":"1분기"}],"genres":[{"id":3,"name":"SF"}],"type":["TV"]}}"#
            ))
        let client = LiveMetadataClient(
            preferences: Preferences(defaults: defaults), client: stub.client)

        await client.refresh()

        #expect(stub.requests.first?.url?.path() == "/api/animes/meta-data-group")
        #expect(client.cachedSeasonYears() == [2026])
        #expect(client.cachedGenres() == [Genre(id: 3, name: "SF")])
        #expect(defaults.stringArray(forKey: "animeType") == ["TV"])
        let seasons = try JSONDecoder().decode(
            [Genre].self, from: try #require(defaults.data(forKey: "seasonQuater")))
        #expect(seasons == [Genre(id: 1, name: "1분기")])
    }
}
