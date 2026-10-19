import AuthClientInterface
import ClientCore
import Networking

/// `api/users/*` (레거시 `LogoutAPI`)
public struct LiveAuthClient: AuthClient {
    private let client: HTTPClient
    private let onLoggedOut: @Sendable () async -> Void

    /// - Parameters:
    ///   - client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    ///   - onLoggedOut: 이 기기의 로그인 정보 정리 (App: 사용자 정보 삭제 + `AuthSession.signOut(.userLogout)`)
    public init(client: HTTPClient, onLoggedOut: @escaping @Sendable () async -> Void) {
        self.client = client
        self.onLoggedOut = onLoggedOut
    }

    public func logout() async {
        // 레거시: 응답이 성공이든 실패든 로그아웃한다 (EditEmailViewModel.swift:44-63)
        _ = try? await client.send(Self.logoutEndpoint)
        await onLoggedOut()
    }

    static let logoutEndpoint = Endpoint<EmptyResult>(
        method: .post,
        path: "api/users/logout",
        requiresAuth: true
    )
}
