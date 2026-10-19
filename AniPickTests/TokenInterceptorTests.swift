//
//  TokenInterceptorTests.swift
//  AniPickTests
//
//  스펙: notes/2026-10-18-T-session-legacy-wiring.md 5절 (S1~S8, D1~D8)
//  실제 Alamofire Session + TokenInterceptor + 가짜 서버 + 실제 AuthSession(가짜 갱신)
//

import Alamofire
import ClientCore
import Foundation
import Security
import Session
import Storage
import Testing

@testable import AniPick

private struct Payload: Decodable, Equatable {
    let code: Int
    let result: String
}

private enum Body {
    static let ok = #"{"code":200,"value":"OK","result":"ok"}"#
    static let expired = #"{"code":119,"value":"FAIL","errorValue":"토큰 만료","result":null}"#
}

private let newTokens = TokenPair(accessToken: "A2", refreshToken: "R2")

@Suite("TokenInterceptor", .timeLimit(.minutes(1)))
final class TokenInterceptorTests {
    private let service = "com.moana.AniPickTests.\(UUID().uuidString)"
    private let suiteName = "com.moana.AniPickTests.\(UUID().uuidString)"
    private let server = StubServer()
    private let tokenStore: AuthTokenStore

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        tokenStore = AuthTokenStore(secureStore: Keychain(service: service), defaults: defaults)
        tokenStore.setAccessToken("A1")
        tokenStore.setRefreshToken("R1")
    }

    deinit {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private func makeClient(
        _ outcome: FakeRefresher.Outcome,
        delay: Duration = .zero
    ) -> (Alamofire.Session, AuthSession, FakeRefresher) {
        let refresher = FakeRefresher(outcome, delay: delay)
        let authSession = AuthSession(tokenStore: tokenStore, refresher: refresher)
        let client = Alamofire.Session(
            configuration: server.configuration,
            interceptor: TokenInterceptor(tokens: authSession)
        )
        return (client, authSession, refresher)
    }

    /// 새 토큰(A2)으로 오면 정상, 그 밖에는 만료로 응답한다.
    private func expiredUnlessNewToken() {
        server.respond { request in
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer A2" {
                return .json(status: 200, body: Body.ok)
            }
            return .json(status: 401, body: Body.expired)
        }
    }

    private func fetch(
        _ client: Alamofire.Session,
        _ path: String = "api/anime"
    ) async -> Result<Payload, AFError> {
        return await client.request(server.url(path))
            .validate()
            .serializingDecodable(Payload.self)
            .result
    }

    /// 표지 이벤트(`.userLogout`)를 보내고, 표지 전까지 쌓인 이벤트를 읽는다.
    private func eventsBeforeMarker(_ session: AuthSession) async -> [SessionEvent] {
        await session.signOut(.userLogout)
        var events: [SessionEvent] = []
        for await event in session.events {
            guard event != .signedOut(.userLogout) else {
                break
            }
            events.append(event)
        }
        return events
    }

    // MARK: - 갱신

    @Test("S1. 만료 응답을 받으면 갱신하고 새 토큰으로 다시 보낸다")
    func refreshesAndRetries() async {
        let (client, authSession, refresher) = makeClient(.tokens(newTokens))
        expiredUnlessNewToken()

        let result = await fetch(client)

        #expect(result.success == Payload(code: 200, result: "ok"))
        #expect(server.authorizations == ["Bearer A1", "Bearer A2"])
        #expect(await refresher.callCount == 1)
        #expect(tokenStore.accessToken == "A2")
        #expect(tokenStore.refreshToken == "R2")
        #expect(await eventsBeforeMarker(authSession).isEmpty)
    }

    @Test("S2. 동시에 10개가 만료돼도 갱신은 1번, 모두 성공")
    func sharesRefreshAcrossConcurrentRequests() async {
        let (client, _, refresher) = makeClient(.tokens(newTokens), delay: .milliseconds(200))
        expiredUnlessNewToken()

        let results = await withTaskGroup(of: Result<Payload, AFError>.self) { group in
            for _ in 0..<10 {
                group.addTask { await self.fetch(client) }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == 10)
        #expect(results.allSatisfy { $0.success != nil })
        #expect(await refresher.callCount == 1)
    }

    @Test("S3·D6. 서버가 갱신을 거절하면 모두 실패하고, 토큰을 지우고, 만료를 1번만 알린다")
    func expiresWhenRefreshRejected() async {
        let (client, authSession, refresher) = makeClient(.rejected, delay: .milliseconds(200))
        server.respondAlways(.json(status: 401, body: Body.expired))

        let results = await withTaskGroup(of: Result<Payload, AFError>.self) { group in
            for _ in 0..<10 {
                group.addTask { await self.fetch(client) }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.allSatisfy { $0.success == nil })
        #expect(server.requests.count == 10)
        #expect(await refresher.callCount == 1)
        #expect(tokenStore.accessToken == "")
        #expect(tokenStore.refreshToken == "")
        #expect(await eventsBeforeMarker(authSession) == [.signedOut(.expired)])
    }

    @Test(
        "S4. 갱신이 일시 오류로 실패하면 토큰을 유지하고 화면 전환도 없다",
        arguments: [TransportError.offline, .timeout, .cancelled]
    )
    func keepsTokensOnTransientRefreshFailure(error: TransportError) async {
        let (client, authSession, refresher) = makeClient(.failure(error))
        server.respondAlways(.json(status: 401, body: Body.expired))

        let result = await fetch(client)

        #expect(result.success == nil)
        #expect(server.requests.count == 1)
        #expect(await refresher.callCount == 1)
        #expect(tokenStore.accessToken == "A1")
        #expect(tokenStore.refreshToken == "R1")
        #expect(await eventsBeforeMarker(authSession).isEmpty)
    }

    @Test("S5. 다시 보낸 요청이 또 만료되면 더 갱신하지 않고 실패로 끝낸다")
    func retriesAtMostOnce() async {
        let (client, authSession, refresher) = makeClient(.tokens(newTokens))
        server.respondAlways(.json(status: 401, body: Body.expired))

        let result = await fetch(client)

        #expect(result.success == nil)
        #expect(server.authorizations == ["Bearer A1", "Bearer A2"])
        #expect(await refresher.callCount == 1)
        #expect(tokenStore.accessToken == "A2")
        #expect(await eventsBeforeMarker(authSession).isEmpty)
    }

    // MARK: - 토큰 붙이기 (현재와 같음)

    @Test("S6. 일반 경로에는 Bearer 토큰을 붙이고, 제외 경로에는 붙이지 않는다")
    func attachesTokenExceptExcludedPaths() async {
        let (client, _, _) = makeClient(.rejected)
        server.respondAlways(.json(status: 200, body: Body.ok))

        _ = await fetch(client, "api/anime")
        _ = await fetch(client, "api/users/me")

        #expect(server.authorizations == ["Bearer A1", nil])
    }

    @Test("S7. 토큰이 없으면 빈 Bearer를 붙인다")
    func attachesEmptyBearerWithoutToken() async {
        tokenStore.setAccessToken("")
        let (client, _, _) = makeClient(.rejected)
        server.respondAlways(.json(status: 200, body: Body.ok))

        _ = await fetch(client)

        #expect(server.authorizations == ["Bearer "])
    }

    @Test("S8. 타임아웃은 갱신·재시도하지 않는다")
    func doesNotRetryTimeout() async {
        let (client, _, refresher) = makeClient(.tokens(newTokens))
        server.respondAlways(.failure(.timedOut))

        let result = await fetch(client)

        #expect(result.success == nil)
        #expect(server.requests.count == 1)
        #expect(await refresher.callCount == 0)
    }

    // MARK: - 파생 케이스

    @Test("D1. 200 응답의 code 119도 디코딩이 실패하면 갱신 후 다시 보낸다")
    func refreshesOnDecodingFailureWithCode119() async {
        let (client, _, refresher) = makeClient(.tokens(newTokens))
        server.respond { request in
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer A2" {
                return .json(status: 200, body: Body.ok)
            }
            return .json(status: 200, body: Body.expired)
        }

        // validate() 없이 받는다 — result가 null이라 Payload 디코딩이 실패한다
        let result = await client.request(server.url("api/anime"))
            .serializingDecodable(Payload.self)
            .result

        #expect(result.success == Payload(code: 200, result: "ok"))
        #expect(await refresher.callCount == 1)
    }

    @Test(
        "D2·D3. 만료가 아닌 서버 오류는 갱신·재시도하지 않는다",
        arguments: [#"{"code":500,"value":"FAIL","result":null}"#, "<html>error</html>"]
    )
    func doesNotRefreshOnOtherServerErrors(body: String) async {
        let (client, _, refresher) = makeClient(.tokens(newTokens))
        server.respondAlways(.json(status: 500, body: body))

        let result = await fetch(client)

        #expect(result.success == nil)
        #expect(server.requests.count == 1)
        #expect(await refresher.callCount == 0)
    }

    @Test("D4. 제외 경로가 만료 응답을 받아도 1번만 다시 보내고 멈춘다")
    func excludedPathStopsAfterOneRetry() async {
        let (client, authSession, refresher) = makeClient(.tokens(newTokens))
        server.respondAlways(.json(status: 401, body: Body.expired))

        let result = await fetch(client, "api/users/me")

        #expect(result.success == nil)
        #expect(server.authorizations == [nil, nil])
        #expect(await refresher.callCount == 1)
        #expect(await eventsBeforeMarker(authSession).isEmpty)
    }

    @Test("D5. refresh 토큰이 없으면 서버에 묻지 않고 만료 처리한다")
    func expiresWithoutRefreshToken() async {
        tokenStore.setRefreshToken("")
        let (client, authSession, refresher) = makeClient(.tokens(newTokens))
        server.respondAlways(.json(status: 401, body: Body.expired))

        let result = await fetch(client)

        #expect(result.success == nil)
        #expect(await refresher.callCount == 0)
        #expect(tokenStore.accessToken == "")
        #expect(await eventsBeforeMarker(authSession) == [.signedOut(.expired)])
    }

    @Test("D7. 갱신을 기다리는 동안 요청을 취소하면 취소로 끝나고 다시 보내지 않는다")
    func cancelWhileRefreshing() async throws {
        let (client, _, refresher) = makeClient(.tokens(newTokens), delay: .milliseconds(200))
        expiredUnlessNewToken()

        let request = client.request(server.url("api/anime")).validate()
        let response = Task { await request.serializingDecodable(Payload.self).result }
        try #require(await refresher.waitUntilCalled())
        request.cancel()
        let result = await response.value

        #expect(result.failure?.isExplicitlyCancelledError == true)
        // 갱신이 끝난 뒤에도 취소된 요청을 다시 보내지 않는지 본다
        try await Task.sleep(for: .milliseconds(400))
        #expect(server.requests.count == 1)
        #expect(tokenStore.accessToken == "A2")
    }

    @Test("D8. 갱신 중에 만료된 새 요청은 진행 중인 갱신을 함께 기다린다")
    func joinsInFlightRefresh() async throws {
        let (client, _, refresher) = makeClient(.tokens(newTokens), delay: .milliseconds(300))
        expiredUnlessNewToken()

        async let first = fetch(client)
        try #require(await refresher.waitUntilCalled())
        async let second = fetch(client)
        let results = await [first, second]

        #expect(results.allSatisfy { $0.success != nil })
        #expect(await refresher.callCount == 1)
    }
}

extension Result {
    fileprivate var success: Success? {
        guard case .success(let value) = self else {
            return nil
        }
        return value
    }

    fileprivate var failure: Failure? {
        guard case .failure(let error) = self else {
            return nil
        }
        return error
    }
}
