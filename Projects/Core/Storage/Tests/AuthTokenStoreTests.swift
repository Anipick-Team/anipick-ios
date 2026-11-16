import Foundation
import Testing

import Storage

/// 명세: notes/2026-10-18-T-keychain-token-storage.md 5절 (S = 시나리오, D = 파생 케이스)
@Suite("AuthTokenStore")
final class AuthTokenStoreTests {
    private let suiteName = "com.moana.StorageTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let keychain = InMemorySecureStore()
    private let store: AuthTokenStore

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = AuthTokenStore(secureStore: keychain, defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Given

    private func givenLegacyTokens(access: String?, refresh: String?) {
        defaults.set(access, forKey: "accessToken")
        defaults.set(refresh, forKey: "refreshToken")
    }

    private func givenKeychainTokens(access: String?, refresh: String?) throws {
        if let access {
            try keychain.setString(access, for: "accessToken")
        }
        if let refresh {
            try keychain.setString(refresh, for: "refreshToken")
        }
    }

    private func givenLaunchedBefore() {
        defaults.set(true, forKey: "hasLaunchedAfterInstall")
    }

    private func legacyValue(_ key: String) -> String? {
        return defaults.string(forKey: key)
    }

    // MARK: - 이관

    @Test("S1 업데이트 첫 실행: UD 토큰을 KC로 옮기고 UD에서 지운다")
    func migratesLegacyTokens() {
        givenLegacyTokens(access: "A", refresh: "R")

        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "accessToken") == "A")
        #expect(keychain.storedString(for: "refreshToken") == "R")
        #expect(legacyValue("accessToken") == nil)
        #expect(legacyValue("refreshToken") == nil)
        #expect(store.accessToken == "A")
        #expect(store.refreshToken == "R")
        #expect(defaults.bool(forKey: "hasLaunchedAfterInstall"))
    }

    @Test("S2 업데이트 첫 실행: UD 토큰이 없거나 빈 값이면 로그아웃 상태 유지", arguments: [nil, ""])
    func keepsLoggedOutWhenNoLegacyToken(legacy: String?) {
        givenLegacyTokens(access: legacy, refresh: legacy)

        store.prepareOnLaunch()

        #expect(keychain.isEmpty)
        #expect(store.accessToken == "")
        #expect(store.refreshToken == "")
    }

    @Test("S3 이관 중 KC 쓰기가 실패하면 UD 토큰을 유지한다")
    func keepsLegacyTokensWhenKeychainWriteFails() {
        givenLegacyTokens(access: "A", refresh: "R")
        keychain.update { $0.failingWrites = ["accessToken", "refreshToken"] }

        store.prepareOnLaunch()

        #expect(legacyValue("accessToken") == "A")
        #expect(legacyValue("refreshToken") == "R")
        #expect(store.accessToken == "A")
        #expect(store.refreshToken == "R")
    }

    @Test("S4 이관에 실패했으면 다음 실행에 다시 시도한다")
    func retriesMigrationOnNextLaunch() {
        givenLegacyTokens(access: "A", refresh: "R")
        keychain.update { $0.failingWrites = ["accessToken", "refreshToken"] }
        store.prepareOnLaunch()

        keychain.update { $0.failingWrites = [] }
        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "accessToken") == "A")
        #expect(keychain.storedString(for: "refreshToken") == "R")
        #expect(legacyValue("accessToken") == nil)
        #expect(legacyValue("refreshToken") == nil)
    }

    @Test("S5 이관이 끝난 뒤 재실행하면 KC에 다시 쓰지 않는다")
    func doesNotMigrateAgain() {
        givenLegacyTokens(access: "A", refresh: "R")
        store.prepareOnLaunch()
        let writesAfterMigration = keychain.writeCount

        store.prepareOnLaunch()

        #expect(writesAfterMigration > 0)
        #expect(keychain.writeCount == writesAfterMigration)
        #expect(keychain.storedString(for: "accessToken") == "A")
    }

    // MARK: - 읽기

    @Test("S6 KC와 UD에 모두 있으면 KC 값을 읽는다")
    func prefersKeychainValue() throws {
        try givenKeychainTokens(access: "K", refresh: nil)
        givenLegacyTokens(access: "U", refresh: nil)

        #expect(store.accessToken == "K")
    }

    @Test("S7 KC에 없으면 UD 값을 읽는다")
    func fallsBackToLegacyValue() {
        givenLegacyTokens(access: "U", refresh: "UR")

        #expect(store.accessToken == "U")
        #expect(store.refreshToken == "UR")
    }

    @Test("S13·D11 KC 읽기가 실패(잠금)하면 UD 값, 그것도 없으면 빈 문자열")
    func fallsBackWhenKeychainReadFails() throws {
        try givenKeychainTokens(access: "K", refresh: "KR")
        keychain.update { $0.failingReads = ["accessToken", "refreshToken"] }
        givenLegacyTokens(access: "U", refresh: nil)

        #expect(store.accessToken == "U")
        #expect(store.refreshToken == "")
    }

    // MARK: - 쓰기

    @Test("S8 토큰을 저장하면 KC에만 쓴다")
    func storesTokenInKeychain() {
        givenLaunchedBefore()

        store.setAccessToken("N")
        store.setRefreshToken("NR")

        #expect(keychain.storedString(for: "accessToken") == "N")
        #expect(keychain.storedString(for: "refreshToken") == "NR")
        #expect(legacyValue("accessToken") == nil)
        #expect(legacyValue("refreshToken") == nil)
        #expect(store.accessToken == "N")
    }

    @Test("S9 빈 문자열을 저장하면 KC와 UD의 토큰을 모두 지운다")
    func removesTokensOnEmptyString() throws {
        try givenKeychainTokens(access: "K", refresh: "KR")
        givenLegacyTokens(access: "U", refresh: "UR")

        store.setAccessToken("")
        store.setRefreshToken("")

        #expect(keychain.isEmpty)
        #expect(legacyValue("accessToken") == nil)
        #expect(legacyValue("refreshToken") == nil)
        #expect(store.accessToken == "")
        #expect(store.refreshToken == "")
    }

    @Test("S10·D12 KC 쓰기가 실패(잠금)하면 UD에 저장하고 KC의 옛 값을 지운다")
    func fallsBackToLegacyWhenKeychainWriteFails() throws {
        try givenKeychainTokens(access: "O", refresh: nil)
        keychain.update { $0.failingWrites = ["accessToken"] }

        store.setAccessToken("N")

        #expect(legacyValue("accessToken") == "N")
        #expect(keychain.storedString(for: "accessToken") == nil)
        #expect(store.accessToken == "N")
    }

    // MARK: - 재설치

    @Test("S11 새로 설치한 첫 실행이면 이전 설치가 KC에 남긴 토큰을 지운다")
    func clearsKeychainOnFreshInstall() throws {
        try givenKeychainTokens(access: "A", refresh: "R")

        store.prepareOnLaunch()

        #expect(keychain.isEmpty)
        #expect(store.accessToken == "")
        #expect(defaults.bool(forKey: "hasLaunchedAfterInstall"))
    }

    @Test("S12 실행한 적이 있으면 KC 토큰을 유지한다")
    func keepsKeychainWhenLaunchedBefore() throws {
        try givenKeychainTokens(access: "A", refresh: "R")
        givenLaunchedBefore()

        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "accessToken") == "A")
        #expect(store.accessToken == "A")
    }

    // MARK: - 경계값·빈 값

    @Test("D1 이관 시 access만 있으면 access만 옮긴다")
    func migratesAccessTokenOnly() {
        givenLegacyTokens(access: "A", refresh: nil)

        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "accessToken") == "A")
        #expect(keychain.storedString(for: "refreshToken") == nil)
        #expect(legacyValue("accessToken") == nil)
        #expect(store.refreshToken == "")
    }

    @Test("D2 이관 시 refresh만 있으면 refresh만 옮긴다")
    func migratesRefreshTokenOnly() {
        givenLegacyTokens(access: nil, refresh: "R")

        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "refreshToken") == "R")
        #expect(keychain.storedString(for: "accessToken") == nil)
        #expect(store.accessToken == "")
    }

    @Test("D3 UD 값이 빈 문자열이면 KC에 쓰지 않고 UD 키를 지운다")
    func dropsEmptyLegacyValues() {
        givenLegacyTokens(access: "", refresh: "")

        store.prepareOnLaunch()

        #expect(keychain.writeCount == 0)
        #expect(defaults.object(forKey: "accessToken") == nil)
        #expect(defaults.object(forKey: "refreshToken") == nil)
    }

    @Test("D4 토큰이 없을 때 빈 문자열을 저장해도 문제없다")
    func removesMissingTokenSafely() {
        store.setAccessToken("")

        #expect(store.accessToken == "")
    }

    // MARK: - 에러

    @Test("D5 이관 중 refresh만 KC 쓰기에 실패하면 access만 옮긴다")
    func migratesPartially() {
        givenLegacyTokens(access: "A", refresh: "R")
        keychain.update { $0.failingWrites = ["refreshToken"] }

        store.prepareOnLaunch()

        #expect(keychain.storedString(for: "accessToken") == "A")
        #expect(legacyValue("accessToken") == nil)
        #expect(legacyValue("refreshToken") == "R")
        #expect(store.accessToken == "A")
        #expect(store.refreshToken == "R")
    }

    @Test("D6 이관 검증 재읽기 값이 다르면 실패로 보고 UD를 유지한다")
    func treatsMismatchedReadAsFailure() {
        givenLegacyTokens(access: "A", refresh: nil)
        keychain.update { $0.corruptedReads = ["accessToken"] }

        store.prepareOnLaunch()

        #expect(legacyValue("accessToken") == "A")
        #expect(store.accessToken == "A")
    }

    @Test("D7 이관 검증 재읽기가 실패하면 실패로 보고 UD를 유지한다")
    func treatsFailedReadAsFailure() {
        givenLegacyTokens(access: "A", refresh: nil)
        keychain.update { $0.failingReads = ["accessToken"] }

        store.prepareOnLaunch()

        #expect(legacyValue("accessToken") == "A")
        #expect(store.accessToken == "A")
    }

    @Test("D8 로그아웃 시 KC 삭제가 실패하면 빈 값으로 덮어써 토큰이 살아나지 않게 한다")
    func overwritesWhenKeychainDeleteFails() throws {
        try givenKeychainTokens(access: "O", refresh: "OR")
        keychain.update { $0.failingDeletes = ["accessToken", "refreshToken"] }

        store.setAccessToken("")
        store.setRefreshToken("")

        #expect(store.accessToken == "")
        #expect(store.refreshToken == "")
    }

    @Test("D14 KC에 덮어쓴 빈 값이 남아 있으면 UD 값을 읽는다")
    func ignoresEmptyKeychainValue() throws {
        // D8로 KC에 빈 값이 남은 뒤, 다음 저장이 KC 실패로 UD에 들어간 상태
        try givenKeychainTokens(access: "", refresh: nil)
        givenLegacyTokens(access: "N", refresh: nil)

        #expect(store.accessToken == "N")
    }

    @Test("D9 재설치 정리 중 KC 삭제가 실패하면 빈 값으로 덮어쓰고 다음 실행에 다시 정리한다")
    func retriesFreshInstallCleanup() throws {
        try givenKeychainTokens(access: "A", refresh: "R")
        keychain.update { $0.failingDeletes = ["accessToken", "refreshToken"] }

        store.prepareOnLaunch()

        #expect(store.accessToken == "")
        #expect(store.refreshToken == "")
        #expect(defaults.bool(forKey: "hasLaunchedAfterInstall") == false)
    }
}

// MARK: - 동시성 (실제 Keychain)

@Suite("AuthTokenStore 동시성")
struct AuthTokenStoreConcurrencyTests {
    @Test("D10 여러 스레드에서 동시에 읽고 써도 쓴 값 중 하나를 읽는다")
    func concurrentAccess() async throws {
        let suiteName = "com.moana.StorageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let keychain = Keychain(service: "com.moana.StorageTests.\(UUID().uuidString)")
        let store = AuthTokenStore(secureStore: keychain, defaults: defaults)
        defer {
            try? keychain.removeValue(for: "accessToken")
            defaults.removePersistentDomain(forName: suiteName)
        }
        let written = Set((0..<50).map { "T\($0)" })

        await withTaskGroup(of: Void.self) { group in
            for token in written {
                group.addTask { store.setAccessToken(token) }
                group.addTask { _ = store.accessToken }
            }
        }

        #expect(written.contains(store.accessToken))
    }
}
