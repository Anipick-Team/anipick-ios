import Foundation
import Testing
import os

@testable import AuthClientLive

@Suite("LiveAuthClient", .timeLimit(.minutes(1)))
struct LiveAuthClientTests {
    private let loggedOut = OSAllocatedUnfairLock(initialState: 0)

    private func makeClient(_ stub: ClientStub, token: String? = nil) -> LiveAuthClient {
        return LiveAuthClient(
            client: stub.client,
            accessToken: { token },
            onLoggedOut: { [loggedOut] in loggedOut.withLock { $0 += 1 } }
        )
    }

    @Test("M15. 즉시 로그아웃: 서버 응답을 기다리지 않고 정리하고, 정리 전에 읽은 토큰을 요청에 싣는다")
    func logsOutImmediately() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#), delay: 1)
        let start = ContinuousClock.now

        await makeClient(stub, token: "BEFORE").logoutImmediately()

        #expect(ContinuousClock.now - start < .milliseconds(500))
        #expect(loggedOut.withLock { $0 } == 1)
        // 요청은 백그라운드로 나간다 — 도착할 때까지 기다린다
        let deadline = ContinuousClock.now + .seconds(2)
        while stub.requests.isEmpty, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/users/logout")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer BEFORE")
    }

    @Test("E14. POST api/users/logout을 토큰과 함께 보내고 로그인 정보를 정리한다")
    func logsOut() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        await makeClient(stub).logout()

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/users/logout")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(loggedOut.withLock { $0 } == 1)
    }

    @Test(
        "E14. 서버가 거절하거나 전송에 실패해도 로그인 정보를 정리한다",
        arguments: [
            ClientStub.Reply.json(#"{"code":500,"value":"FAIL","errorValue":null}"#),
            .failure(.notConnectedToInternet),
        ]
    )
    func logsOutEvenOnFailure(reply: ClientStub.Reply) async {
        await makeClient(ClientStub(reply)).logout()

        #expect(loggedOut.withLock { $0 } == 1)
    }
}
