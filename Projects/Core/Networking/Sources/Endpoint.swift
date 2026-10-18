import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum RequestBody: Sendable {
    case none
    /// `Content-Type: application/json`으로 보낸다.
    case json(any Encodable & Sendable)
    /// `URLSession.upload(for:from:)`로 보낸다.
    case multipart(MultipartForm)
}

/// 요청 1개의 정의.
///
/// 인증 필요 여부(`requiresAuth`)를 요청마다 명시한다. 레거시는 경로 부분 문자열로 판정해
/// `/users`가 들어간 인증 API가 토큰 없이 나갈 수 있었다.
public struct Endpoint<Result: Decodable & Sendable>: Sendable {
    public var method: HTTPMethod
    /// 기본 주소 뒤에 붙는 경로. 예: `"api/users/login"`
    public var path: String
    public var query: [URLQueryItem]
    /// 같은 이름의 기본 헤더(`Authorization` 포함)보다 우선한다.
    public var headers: [String: String]
    public var body: RequestBody
    public var requiresAuth: Bool

    public init(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: RequestBody = .none,
        requiresAuth: Bool
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }
}
