import Foundation
import os

/// 실제 네트워크 없이 요청을 가로채는 가짜 서버.
/// 테스트가 병렬로 돌아도 섞이지 않도록 서버마다 고유한 호스트를 쓴다.
final class StubServer: Sendable {
    enum Reply: Sendable {
        case json(status: Int, body: String)
        case failure(URLError.Code)
    }

    struct State: Sendable {
        var replies: [Reply] = []
        var requests: [URLRequest] = []
        var bodies: [Data] = []
    }

    let host = "stub-\(UUID().uuidString.lowercased()).test"
    private let state = OSAllocatedUnfairLock(initialState: State())

    var baseURL: URL {
        return URL(string: "https://\(host)/")!
    }

    var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    // 등록 표가 서버를 강하게 붙잡으므로 테스트 프로세스가 끝날 때까지 남는다 (테스트당 객체 1개).
    init() {
        StubURLProtocol.register(self)
    }

    /// 요청마다 차례로 응답한다. 응답이 하나 남으면 그 응답을 계속 쓴다.
    func reply(_ replies: Reply...) {
        state.withLock { $0.replies = replies }
    }

    var requests: [URLRequest] {
        return state.withLock { $0.requests }
    }

    var bodies: [Data] {
        return state.withLock { $0.bodies }
    }

    fileprivate func handle(_ request: URLRequest, body: Data) -> Reply {
        return state.withLock { state in
            state.requests.append(request)
            state.bodies.append(body)
            guard state.replies.count > 1 else {
                return state.replies.first ?? .failure(.badServerResponse)
            }
            return state.replies.removeFirst()
        }
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private static let servers = OSAllocatedUnfairLock(initialState: [String: StubServer]())

    static func register(_ server: StubServer) {
        servers.withLock { $0[server.host] = server }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let host = url.host,
            let server = Self.servers.withLock({ $0[host] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        switch server.handle(request, body: Self.body(of: request)) {
        case .json(let status, let body):
            let response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}

    /// URLProtocol에는 본문이 `httpBody`가 아니라 스트림으로 들어오는 경우가 있다.
    private static func body(of request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return Data()
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}
