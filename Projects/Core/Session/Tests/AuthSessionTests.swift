import Foundation
import Security
import Testing

import ClientCore
import Networking
import Storage

@testable import Session

/// 갱신 결과를 정해 두고 호출을 기록하는 가짜. 응답을 늦춰 동시 호출을 재현한다.
actor FakeRefresher: TokenRefreshing {
    enum Outcome: Sendable {
        case tokens(TokenPair)
        case rejected
        case failure(TransportError)
    }

    private let outcome: Outcome
    private let delay: Duration
    private(set) var receivedRefreshTokens: [String] = []

    init(_ outcome: Outcome, delay: Duration = .zero) {
        self.outcome = outcome
        self.delay = delay
    }

    var callCount: Int {
        return receivedRefreshTokens.count
    }

    func refresh(refreshToken: String) async throws(TransportError) -> TokenPair? {
        receivedRefreshTokens.append(refreshToken)
        try? await Task.sleep(for: delay)
        switch outcome {
        case .tokens(let tokens):
            return tokens
        case .rejected:
            return nil
        case .failure(let error):
            throw error
        }
    }
}

@Suite("AuthSession")
final class AuthSessionTests {
    private let service = "com.moana.SessionTests.\(UUID().uuidString)"
    private let suiteName = "com.moana.SessionTests.\(UUID().uuidString)"
    private let tokenStore: AuthTokenStore

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        tokenStore = AuthTokenStore(secureStore: Keychain(service: service), defaults: defaults)
    }

    deinit {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private func makeSession(
        _ outcome: FakeRefresher.Outcome = .rejected,
        delay: Duration = .zero
    ) -> (AuthSession, FakeRefresher) {
        let refresher = FakeRefresher(outcome, delay: delay)
        return (AuthSession(tokenStore: tokenStore, refresher: refresher), refresher)
    }

    private func givenTokens(access: String, refresh: String) {
        tokenStore.setAccessToken(access)
        tokenStore.setRefreshToken(refresh)
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

    // MARK: - 토큰

    @Test("저장된 access 토큰을 돌려주고, 없으면 nil")
    func returnsAccessToken() async {
        let (session, _) = makeSession()
        #expect(await session.accessToken() == nil)
        #expect(await session.hasTokens == false)

        givenTokens(access: "A", refresh: "R")

        #expect(await session.accessToken() == "A")
        #expect(await session.hasTokens)
    }

    @Test("로그인 토큰을 저장해도 이벤트를 내보내지 않는다")
    func storesTokensWithoutEvent() async {
        let (session, _) = makeSession()

        await session.store(TokenPair(accessToken: "A", refreshToken: "R"))

        #expect(await session.accessToken() == "A")
        #expect(tokenStore.refreshToken == "R")
        #expect(await eventsBeforeMarker(session).isEmpty)
    }

    @Test("로그아웃·탈퇴는 토큰을 지우고 이유를 알린다", arguments: [SignOutReason.userLogout, .withdrawal])
    func signsOut(reason: SignOutReason) async {
        let (session, _) = makeSession()
        givenTokens(access: "A", refresh: "R")

        await session.signOut(reason)

        var iterator = session.events.makeAsyncIterator()
        #expect(await iterator.next() == .signedOut(reason))
        #expect(await session.accessToken() == nil)
        #expect(tokenStore.refreshToken == "")
    }

    // MARK: - 갱신

    @Test("갱신에 성공하면 새 토큰을 저장한다")
    func refreshesTokens() async throws {
        let (session, refresher) = makeSession(
            .tokens(TokenPair(accessToken: "A2", refreshToken: "R2")))
        givenTokens(access: "A1", refresh: "R1")

        try await session.refreshAccessToken()

        #expect(await session.accessToken() == "A2")
        #expect(tokenStore.refreshToken == "R2")
        #expect(await refresher.receivedRefreshTokens == ["R1"])
    }

    @Test("동시에 10번 갱신을 요청해도 서버에는 1번만 보낸다")
    func sharesInFlightRefresh() async throws {
        let (session, refresher) = makeSession(
            .tokens(TokenPair(accessToken: "A2", refreshToken: "R2")),
            delay: .milliseconds(200)
        )
        givenTokens(access: "A1", refresh: "R1")

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { try await session.refreshAccessToken() }
            }
            try await group.waitForAll()
        }

        #expect(await refresher.callCount == 1)
        #expect(await session.accessToken() == "A2")
    }

    // MARK: - 만료

    @Test("서버가 갱신을 거절하면 토큰을 지우고 만료를 알린다")
    func expiresWhenRejected() async {
        let (session, _) = makeSession(.rejected)
        givenTokens(access: "A1", refresh: "R1")

        await #expect(throws: TransportError.sessionExpired) {
            try await session.refreshAccessToken()
        }

        #expect(await session.accessToken() == nil)
        #expect(tokenStore.refreshToken == "")
        #expect(await eventsBeforeMarker(session) == [.signedOut(.expired)])
    }

    @Test("동시에 10번 갱신이 거절돼도 만료는 1번만 알리고 모두 sessionExpired")
    func expiresOnceForConcurrentRefresh() async {
        let (session, refresher) = makeSession(.rejected, delay: .milliseconds(200))
        givenTokens(access: "A1", refresh: "R1")

        // 성공하면 nil, 실패하면 던진 에러
        let errors = await withTaskGroup(of: TransportError?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do throws(TransportError) {
                        try await session.refreshAccessToken()
                        return nil
                    } catch {
                        return error
                    }
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        #expect(errors.count == 10)
        #expect(errors.allSatisfy { $0 == .sessionExpired })
        #expect(await refresher.callCount == 1)
        #expect(await eventsBeforeMarker(session) == [.signedOut(.expired)])
    }

    @Test("refresh 토큰이 없으면 서버에 묻지 않고 만료")
    func expiresWithoutRefreshToken() async {
        let (session, refresher) = makeSession(
            .tokens(TokenPair(accessToken: "A2", refreshToken: "R2")))
        givenTokens(access: "A1", refresh: "")

        await #expect(throws: TransportError.sessionExpired) {
            try await session.refreshAccessToken()
        }

        #expect(await refresher.callCount == 0)
        #expect(await eventsBeforeMarker(session) == [.signedOut(.expired)])
    }

    @Test(
        "서버 오류·형식 오류도 만료로 본다",
        arguments: [TransportError.server(status: 500), .server(status: 401), .decoding, .unknown]
    )
    func expiresOnServerFailure(error: TransportError) async {
        let (session, _) = makeSession(.failure(error))
        givenTokens(access: "A1", refresh: "R1")

        await #expect(throws: TransportError.sessionExpired) {
            try await session.refreshAccessToken()
        }

        #expect(await session.accessToken() == nil)
        #expect(await eventsBeforeMarker(session) == [.signedOut(.expired)])
    }

    @Test(
        "일시 오류는 토큰을 유지하고 그 에러를 그대로 던진다",
        arguments: [TransportError.offline, .timeout, .cancelled]
    )
    func keepsTokensOnTransientFailure(error: TransportError) async {
        let (session, _) = makeSession(.failure(error))
        givenTokens(access: "A1", refresh: "R1")

        await #expect(throws: error) {
            try await session.refreshAccessToken()
        }

        #expect(await session.accessToken() == "A1")
        #expect(tokenStore.refreshToken == "R1")
        #expect(await eventsBeforeMarker(session).isEmpty)
    }

    @Test("이미 만료된 뒤 다시 갱신을 요청해도 만료를 반복해 알리지 않는다")
    func doesNotRepeatExpiredEvent() async {
        let (session, _) = makeSession(.rejected)
        givenTokens(access: "A1", refresh: "R1")

        _ = try? await session.refreshAccessToken()
        _ = try? await session.refreshAccessToken()

        #expect(await eventsBeforeMarker(session) == [.signedOut(.expired)])
    }

    // MARK: - 갱신 중 로그아웃 (1-6 D9)

    @Test("갱신 중에 로그아웃하면 늦게 도착한 새 토큰을 저장하지 않는다")
    func discardsRefreshResultAfterSignOut() async throws {
        let (session, refresher) = makeSession(
            .tokens(TokenPair(accessToken: "A2", refreshToken: "R2")),
            delay: .milliseconds(200)
        )
        givenTokens(access: "A1", refresh: "R1")

        let refresh = Task { () -> TransportError? in
            do throws(TransportError) {
                try await session.refreshAccessToken()
                return nil
            } catch {
                return error
            }
        }
        let deadline = ContinuousClock.now + .seconds(2)
        while await refresher.callCount == 0, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
        try #require(await refresher.callCount == 1)
        await session.signOut(.withdrawal)
        let error = await refresh.value

        #expect(error == .sessionExpired)
        #expect(await session.accessToken() == nil)
        #expect(tokenStore.refreshToken == "")
        #expect(await eventsBeforeMarker(session) == [.signedOut(.withdrawal)])
    }
}

@Suite("HTTPTokenRefresher")
struct HTTPTokenRefresherTests {
    @Test("POST api/tokens/refresh에 refresh 토큰을 Bearer로 붙이고, Session 토큰은 쓰지 않는다")
    func buildsEndpoint() {
        let endpoint = HTTPTokenRefresher.endpoint(refreshToken: "R1")

        #expect(endpoint.method == .post)
        #expect(endpoint.path == "api/tokens/refresh")
        #expect(endpoint.headers == ["Authorization": "Bearer R1"])
        #expect(endpoint.requiresAuth == false)
    }

    @Test("code 200이고 토큰이 있을 때만 성공으로 본다")
    func mapsResponse() {
        let tokens = TokenPair(accessToken: "A", refreshToken: "R")

        let success = ServerResponse(code: 200, value: "OK", errorValue: nil, result: tokens)
        let missing = ServerResponse<TokenPair>(
            code: 200, value: "OK", errorValue: nil, result: nil)
        let rejected = ServerResponse(code: 120, value: "FAIL", errorValue: "만료", result: tokens)

        #expect(HTTPTokenRefresher.tokens(from: success) == tokens)
        #expect(HTTPTokenRefresher.tokens(from: missing) == nil)
        #expect(HTTPTokenRefresher.tokens(from: rejected) == nil)
    }
}
