import ClientCore
import Networking

public struct TokenPair: Decodable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// 토큰 갱신 요청. `AuthSession`을 네트워크 없이 시험하기 위한 경계.
public protocol TokenRefreshing: Sendable {
    /// 서버가 갱신을 거절하면 `nil`, 전송 실패는 `TransportError`
    func refresh(refreshToken: String) async throws(TransportError) -> TokenPair?
}

/// 인증 없는 `HTTPClient`로 `POST api/tokens/refresh`를 보낸다
/// (레거시 `AuthAPI.refreshToken`, `TokenInterceptor.swift:91-111`).
public struct HTTPTokenRefresher: TokenRefreshing {
    private let client: HTTPClient

    /// - Parameter client: `tokenProvider`가 없는 클라이언트. Session을 넣으면 갱신 요청이 다시 Session을 부른다.
    public init(client: HTTPClient) {
        self.client = client
    }

    public func refresh(refreshToken: String) async throws(TransportError) -> TokenPair? {
        let response = try await client.send(Self.endpoint(refreshToken: refreshToken))
        return Self.tokens(from: response)
    }

    static func endpoint(refreshToken: String) -> Endpoint<TokenPair> {
        return Endpoint(
            method: .post,
            path: "api/tokens/refresh",
            headers: ["Authorization": "Bearer \(refreshToken)"],
            requiresAuth: false
        )
    }

    static func tokens(from response: ServerResponse<TokenPair>) -> TokenPair? {
        guard response.code == 200 else {
            return nil
        }
        return response.result
    }
}
