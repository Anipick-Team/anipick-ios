import Foundation

/// 인증 토큰(access·refresh) 저장소.
///
/// 토큰은 Keychain(`SecureStore`)에 두고, 레거시가 UserDefaults에 평문으로 저장한 토큰은
/// 앱 시작 시 옮긴다. Keychain에 쓰지 못하면 UserDefaults로 물러선다.
/// 빈 문자열은 "토큰 없음(로그아웃)"을 뜻한다 — 레거시 `UserDefaultsManager`와 같은 약속.
///
/// 명세: notes/2026-10-18-T-keychain-token-storage.md
public struct AuthTokenStore: Sendable {
    /// 레거시 `UserDefaultKey`와 같은 이름 — 이관 전 값과 Keychain 실패 시 대체 저장 위치
    private static let tokenKeys = ["accessToken", "refreshToken"]
    private static let accessTokenKey = "accessToken"
    private static let refreshTokenKey = "refreshToken"
    /// 이 표시가 없으면 새로 설치한 뒤 첫 실행으로 본다 (Keychain 항목은 앱을 지워도 남는다).
    private static let launchedKey = PreferenceKey("hasLaunchedAfterInstall", defaultValue: false)

    private let secureStore: any SecureStore
    private let preferences: Preferences

    public init(secureStore: any SecureStore, defaults: UserDefaults) {
        self.secureStore = secureStore
        self.preferences = Preferences(defaults: defaults)
    }

    /// 앱 시작 시 토큰을 읽는 어떤 코드보다 먼저 1회 호출한다.
    /// 재설치 정리 → UserDefaults 토큰 이관 순서로 진행한다.
    public func prepareOnLaunch() {
        if !preferences.value(for: Self.launchedKey) {
            // 하나라도 지우지 못하면 표시를 남기지 않아 다음 실행에 다시 정리한다 (D9).
            let results = Self.tokenKeys.map { removeFromKeychain($0) }
            if results.allSatisfy({ $0 }) {
                preferences.set(true, for: Self.launchedKey)
            }
        }
        for key in Self.tokenKeys {
            migrateLegacyToken(for: key)
        }
    }

    /// 없으면 빈 문자열
    public var accessToken: String {
        return token(for: Self.accessTokenKey)
    }

    /// 없으면 빈 문자열
    public var refreshToken: String {
        return token(for: Self.refreshTokenKey)
    }

    /// 빈 문자열을 넘기면 삭제한다.
    public func setAccessToken(_ token: String) {
        setToken(token, for: Self.accessTokenKey)
    }

    /// 빈 문자열을 넘기면 삭제한다.
    public func setRefreshToken(_ token: String) {
        setToken(token, for: Self.refreshTokenKey)
    }

    // MARK: - Private

    /// Keychain을 먼저 보고, 없거나 읽지 못하면 UserDefaults를 본다.
    /// Keychain의 빈 문자열은 삭제에 실패해 덮어쓴 값이므로 없는 것으로 본다 (D8).
    private func token(for key: String) -> String {
        if let token = try? secureStore.string(for: key), !token.isEmpty {
            return token
        }
        return preferences.value(for: legacyKey(key))
    }

    private func setToken(_ token: String, for key: String) {
        guard !token.isEmpty else {
            _ = removeFromKeychain(key)
            preferences.removeValue(for: legacyKey(key))
            return
        }
        do {
            try secureStore.setString(token, for: key)
            preferences.removeValue(for: legacyKey(key))
        } catch {
            // Keychain에 남은 옛 토큰이 새 토큰을 가리지 않게 지우고 UserDefaults로 물러선다 (AC8).
            try? secureStore.removeValue(for: key)
            preferences.set(token, for: legacyKey(key))
        }
    }

    /// 다시 읽어 같은 값임을 확인한 뒤에만 UserDefaults에서 지운다 (AC1·AC3).
    private func migrateLegacyToken(for key: String) {
        let legacyToken = preferences.value(for: legacyKey(key))
        guard !legacyToken.isEmpty else {
            preferences.removeValue(for: legacyKey(key))
            return
        }
        do {
            try secureStore.setString(legacyToken, for: key)
            guard try secureStore.string(for: key) == legacyToken else {
                throw KeychainError.invalidData
            }
            preferences.removeValue(for: legacyKey(key))
        } catch {
            // 검증하지 못한 Keychain 값이 UserDefaults 값을 가리지 않게 지운다 (D6·D7).
            try? secureStore.removeValue(for: key)
        }
    }

    /// 삭제에 실패하면 빈 문자열로 덮어써 토큰이 다시 읽히지 않게 한다 (D8·D9).
    /// - Returns: 삭제에 성공했는지
    private func removeFromKeychain(_ key: String) -> Bool {
        do {
            try secureStore.removeValue(for: key)
            return true
        } catch {
            try? secureStore.setString("", for: key)
            return false
        }
    }

    private func legacyKey(_ key: String) -> PreferenceKey<String> {
        return PreferenceKey(key, defaultValue: "")
    }
}
