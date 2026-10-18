import Foundation

/// 인증 토큰(access·refresh) 저장소.
///
/// 토큰은 Keychain(`SecureStore`)에 두고, 레거시가 UserDefaults에 평문으로 저장한 토큰은
/// 앱 시작 시 옮긴다. Keychain에 쓰지 못하면 UserDefaults로 물러선다.
/// 빈 문자열은 "토큰 없음(로그아웃)"을 뜻한다 — 레거시 `UserDefaultsManager`와 같은 약속.
///
/// 명세: notes/2026-10-18-T-keychain-token-storage.md
public struct AuthTokenStore: Sendable {
    private let secureStore: any SecureStore
    private let preferences: Preferences

    public init(secureStore: any SecureStore, defaults: UserDefaults) {
        self.secureStore = secureStore
        self.preferences = Preferences(defaults: defaults)
    }

    /// 앱 시작 시 토큰을 읽는 어떤 코드보다 먼저 1회 호출한다.
    /// 재설치 정리 → UserDefaults 토큰 이관 순서로 진행한다.
    public func prepareOnLaunch() {
    }

    /// 없으면 빈 문자열
    public var accessToken: String {
        return ""
    }

    /// 없으면 빈 문자열
    public var refreshToken: String {
        return ""
    }

    /// 빈 문자열을 넘기면 삭제한다.
    public func setAccessToken(_ token: String) {
    }

    /// 빈 문자열을 넘기면 삭제한다.
    public func setRefreshToken(_ token: String) {
    }
}
