//
//  StubServer.swift
//  AniPickTests
//
//  실제 네트워크 없이 요청을 가로채는 가짜 서버 (Projects/Core/Networking 테스트의 것을 본떴다).
//  요청 헤더로 응답을 고를 수 있게 응답을 함수로 받는다.
//

import Foundation
import os

nonisolated final class StubServer: Sendable {
    enum Reply: Sendable {
        case json(status: Int, body: String)
        case failure(URLError.Code)
    }

    let host = "stub-\(UUID().uuidString.lowercased()).test"
    private let state = OSAllocatedUnfairLock<(
        respond: @Sendable (URLRequest) -> Reply,
        requests: [URLRequest]
    )>(initialState: ({ _ in .failure(.badServerResponse) }, []))

    // 등록 표가 서버를 강하게 붙잡으므로 테스트 프로세스가 끝날 때까지 남는다 (테스트당 객체 1개).
    init() {
        StubURLProtocol.register(self)
    }

    var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    func url(_ path: String) -> URL {
        return URL(string: "https://\(host)/\(path)")!
    }

    func respond(_ respond: @escaping @Sendable (URLRequest) -> Reply) {
        state.withLock { $0.respond = respond }
    }

    func respondAlways(_ reply: Reply) {
        respond { _ in reply }
    }

    var requests: [URLRequest] {
        return state.withLock { $0.requests }
    }

    /// 받은 요청의 Authorization 헤더 (없으면 nil)
    var authorizations: [String?] {
        return requests.map { $0.value(forHTTPHeaderField: "Authorization") }
    }

    fileprivate func handle(_ request: URLRequest) -> Reply {
        let respond = state.withLock { state in
            state.requests.append(request)
            return state.respond
        }
        return respond(request)
    }
}

nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
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
        switch server.handle(request) {
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
}
