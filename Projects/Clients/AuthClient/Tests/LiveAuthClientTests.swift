import Foundation
import Testing
import os

@testable import AuthClientLive

@Suite("LiveAuthClient", .timeLimit(.minutes(1)))
struct LiveAuthClientTests {
    private let loggedOut = OSAllocatedUnfairLock(initialState: 0)

    private func makeClient(_ stub: ClientStub) -> LiveAuthClient {
        return LiveAuthClient(client: stub.client) { [loggedOut] in loggedOut.withLock { $0 += 1 } }
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
