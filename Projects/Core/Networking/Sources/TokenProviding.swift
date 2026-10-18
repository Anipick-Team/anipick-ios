import ClientCore

/// 인증 토큰 제공자. Core/Session의 `AuthSession`이 구현하고, Networking은 이 프로토콜만 안다.
public protocol TokenProviding: Sendable {
    /// 없으면 `nil` (로그아웃 상태)
    func accessToken() async -> String?
    /// 토큰을 갱신한다. 동시 호출을 1회로 합치는 것은 구현의 책임이다.
    /// 갱신할 수 없으면 `.sessionExpired`를 던진다.
    func refreshAccessToken() async throws(TransportError)
}
