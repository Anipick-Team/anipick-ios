import ClientCore
import Foundation
import Networking
import os

/// 모든 요청에 정해 둔 JSON(또는 전송 오류)으로 답하는 가짜 서버. 테스트마다 고유한 호스트를 쓴다.
final class ClientStub: Sendable {
    enum Reply: Sendable {
        case json(String)
        /// 2xx가 아닌 상태와 본문
        case status(Int, String)
        case failure(URLError.Code)
    }

    let host = "review-\(UUID().uuidString.lowercased()).test"
    private let state = OSAllocatedUnfairLock(
        initialState: (reply: Reply.json("{}"), requests: [URLRequest](), delay: 0.0)
    )

    /// - Parameter delay: 응답을 늦추는 초
    init(_ reply: Reply, delay: Double = 0) {
        state.withLock {
            $0.reply = reply
            $0.delay = delay
        }
        ClientStubProtocol.register(self)
    }

    var delay: Double {
        return state.withLock { $0.delay }
    }

    var requests: [URLRequest] {
        return state.withLock { $0.requests }
    }

    /// 인증 요청에 토큰 "T"를 붙이는 클라이언트
    var client: HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ClientStubProtocol.self]
        return HTTPClient(
            baseURL: URL(string: "https://\(host)/")!,
            configuration: configuration,
            tokenProvider: FixedToken()
        )
    }

    fileprivate func handle(_ request: URLRequest) -> Reply {
        return state.withLock {
            $0.requests.append(request)
            return $0.reply
        }
    }
}

private struct FixedToken: TokenProviding {
    func accessToken() async -> String? {
        return "T"
    }

    func refreshAccessToken() async throws(TransportError) {}
}

final class ClientStubProtocol: URLProtocol, @unchecked Sendable {
    private static let stubs = OSAllocatedUnfairLock(initialState: [String: ClientStub]())

    static func register(_ stub: ClientStub) {
        stubs.withLock { $0[stub.host] = stub }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url, let host = url.host,
            let stub = Self.stubs.withLock({ $0[host] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let reply = stub.handle(request)
        DispatchQueue.global().asyncAfter(deadline: .now() + stub.delay) { [self] in
            respond(reply, url: url)
        }
    }

    private func respond(_ reply: ClientStub.Reply, url: URL) {
        switch reply {
        case .json(let body):
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .status(let code, let body):
            let response = HTTPURLResponse(
                url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}
}
