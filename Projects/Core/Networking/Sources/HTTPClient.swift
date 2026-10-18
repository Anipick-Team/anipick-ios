import ClientCore
import Foundation
import os

extension URLSessionConfiguration {
    /// 레거시와 같은 타임아웃: 요청 30초, 리소스 60초 (`NetworkManager.swift:15-16`)
    public static var anipickDefault: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return configuration
    }
}

/// URLSession 기반 요청 경로.
///
/// - 서버 응답 `code == 119`(토큰 만료)이면 토큰을 갱신하고 1회만 재시도한다.
/// - 업무 코드는 판단하지 않고 `ServerResponse`로 돌려준다.
/// - 모든 실패는 `TransportError`로 바꾼다.
public struct HTTPClient: Sendable {
    private static let logger = Logger(subsystem: "com.moana.AniPick", category: "Networking")

    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: (any TokenProviding)?

    /// - Parameter tokenProvider: `nil`이면 인증 없는 클라이언트 (로그인·토큰 갱신 요청용).
    ///   Session이 이 클라이언트로 갱신을 요청해 Networking ↔ Session 순환 의존을 피한다.
    public init(
        baseURL: URL,
        configuration: URLSessionConfiguration = .anipickDefault,
        tokenProvider: (any TokenProviding)?
    ) {
        self.baseURL = baseURL
        self.session = URLSession(configuration: configuration)
        self.tokenProvider = tokenProvider
    }

    /// 요청·디코딩을 호출자 액터(MainActor Store 등) 밖에서 실행한다.
    @concurrent
    public func send<Result>(
        _ endpoint: Endpoint<Result>
    ) async throws(TransportError) -> ServerResponse<Result> {
        let (data, response) = try await perform(endpoint)
        guard endpoint.requiresAuth, Self.isTokenExpired(data) else {
            return try Self.decode(data, response)
        }

        guard let tokenProvider else {
            throw .sessionExpired
        }
        try await tokenProvider.refreshAccessToken()

        let (retryData, retryResponse) = try await perform(endpoint)
        if Self.isTokenExpired(retryData) {
            throw .sessionExpired
        }
        return try Self.decode(retryData, retryResponse)
    }

    // MARK: - Private

    private func perform<Result>(
        _ endpoint: Endpoint<Result>
    ) async throws(TransportError) -> (Data, HTTPURLResponse) {
        var request = try makeRequest(endpoint)
        if endpoint.requiresAuth {
            guard
                let token = await tokenProvider?.accessToken(),
                !token.isEmpty
            else {
                throw .sessionExpired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let start = ContinuousClock.now
        do {
            try Task.checkCancellation()
            let (data, response): (Data, URLResponse)
            if case .multipart(let form) = endpoint.body {
                (data, response) = try await session.upload(for: request, from: form.encoded())
            } else {
                (data, response) = try await session.data(for: request)
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TransportError.unknown
            }
            let elapsed = ContinuousClock.now - start
            Self.logger.debug(
                "\(endpoint.method.rawValue) \(endpoint.path) → \(httpResponse.statusCode) (\(elapsed))"
            )
            return (data, httpResponse)
        } catch {
            throw Self.transportError(from: error)
        }
    }

    private func makeRequest<Result>(
        _ endpoint: Endpoint<Result>
    ) throws(TransportError) -> URLRequest {
        let url = baseURL.appending(path: endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw .unknown
        }
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }
        guard let requestURL = components.url else {
            throw .unknown
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = endpoint.method.rawValue
        switch endpoint.body {
        case .none:
            break
        case .json(let value):
            do {
                request.httpBody = try JSONEncoder().encode(value)
            } catch {
                throw .unknown
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(let form):
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    /// HTTP 상태와 무관하게 본문 `code`로 판정한다 (레거시 `TokenInterceptor.swift:79`).
    private static func isTokenExpired(_ data: Data) -> Bool {
        let serverCode = try? JSONDecoder().decode(ServerCode.self, from: data)
        return serverCode?.code == ServerCode.tokenExpired
    }

    private static func decode<Result: Decodable & Sendable>(
        _ data: Data,
        _ response: HTTPURLResponse
    ) throws(TransportError) -> ServerResponse<Result> {
        guard (200..<300).contains(response.statusCode) else {
            throw .server(status: response.statusCode)
        }
        do {
            let envelope = try JSONDecoder().decode(ServerEnvelope<Result>.self, from: data)
            return ServerResponse(
                code: envelope.code,
                value: envelope.value ?? "",
                errorValue: envelope.errorValue,
                result: envelope.result
            )
        } catch {
            throw .decoding
        }
    }

    static func transportError(from error: any Error) -> TransportError {
        if let transportError = error as? TransportError {
            return transportError
        }
        if error is CancellationError {
            return .cancelled
        }
        guard let urlError = error as? URLError else {
            return .unknown
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .unknown
        }
    }
}
