import AuthClientInterface
import ClientCore
import Networking

/// `api/users/*` (레거시 `LogoutAPI`)
public struct LiveAuthClient: AuthClient {
    private let client: HTTPClient
    private let accessToken: @Sendable () async -> String?
    private let onLoggedOut: @Sendable () async -> Void

    /// - Parameters:
    ///   - client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    ///   - accessToken: 지금 토큰 (`logoutImmediately`가 정리 전에 읽는다)
    ///   - onLoggedOut: 이 기기의 로그인 정보 정리 (App: 사용자 정보 삭제 + `AuthSession.signOut(.userLogout)`)
    public init(
        client: HTTPClient,
        accessToken: @escaping @Sendable () async -> String? = { nil },
        onLoggedOut: @escaping @Sendable () async -> Void
    ) {
        self.client = client
        self.accessToken = accessToken
        self.onLoggedOut = onLoggedOut
    }

    public func logout() async {
        // 레거시: 응답이 성공이든 실패든 로그아웃한다 (EditEmailViewModel.swift:44-63)
        _ = try? await client.send(Self.logoutEndpoint)
        await onLoggedOut()
    }

    public func logoutImmediately() async {
        // HTTPClient는 보내는 시점에 토큰을 읽으므로, 정리보다 먼저 읽어 헤더에 직접 넣는다 (1-6 AC10)
        let endpoint = Self.logoutEndpoint(token: await accessToken() ?? "")
        let client = client
        Task {
            _ = try? await client.send(endpoint)
        }
        await onLoggedOut()
    }

    /// 토큰을 헤더에 직접 넣은 요청. 정리 뒤에 나가도 토큰이 실린다
    static func logoutEndpoint(token: String) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .post,
            path: "api/users/logout",
            headers: ["Authorization": "Bearer \(token)"],
            requiresAuth: false
        )
    }

    static let logoutEndpoint = Endpoint<EmptyResult>(
        method: .post,
        path: "api/users/logout",
        requiresAuth: true
    )
}
