import Foundation
import os

/// 실제 네트워크 없이 이미지 요청에 응답하고 요청 수를 센다. 테스트마다 고유한 호스트를 쓴다.
nonisolated final class ImageStubServer: Sendable {
    let host = "image-\(UUID().uuidString.lowercased()).test"
    private let state = OSAllocatedUnfairLock(
        uncheckedState: (status: 200, body: Data(), delay: Duration.zero, requestCount: 0)
    )

    init() {
        ImageStubProtocol.register(self)
    }

    var session: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageStubProtocol.self]
        return URLSession(configuration: configuration)
    }

    func url(_ path: String) -> URL {
        return URL(string: "https://\(host)/\(path)")!
    }

    func respond(status: Int = 200, body: Data, delay: Duration = .zero) {
        state.withLockUnchecked {
            $0.status = status
            $0.body = body
            $0.delay = delay
        }
    }

    var requestCount: Int {
        return state.withLockUnchecked { $0.requestCount }
    }

    fileprivate func handle() -> (status: Int, body: Data, delay: Duration) {
        return state.withLockUnchecked {
            $0.requestCount += 1
            return ($0.status, $0.body, $0.delay)
        }
    }
}

nonisolated final class ImageStubProtocol: URLProtocol, @unchecked Sendable {
    private static let servers = OSAllocatedUnfairLock(initialState: [String: ImageStubServer]())

    static func register(_ server: ImageStubServer) {
        servers.withLock { $0[server.host] = server }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url, let host = url.host,
            let server = Self.servers.withLock({ $0[host] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let reply = server.handle()
        let delay = reply.delay.components
        let seconds = Double(delay.seconds) + Double(delay.attoseconds) / 1e18
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) { [self] in
            let response = HTTPURLResponse(
                url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: reply.body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
