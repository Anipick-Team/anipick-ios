import ClientCore
import Foundation
import Storage
import Testing
import os

@testable import UserClientInterface
@testable import UserClientLive

/// 가짜 서버로 요청 → 응답 → 저장·후처리까지 확인한다
@Suite("LiveUserClient 흐름", .timeLimit(.minutes(1)))
final class LiveUserClientFlowTests {
    private let suiteName = "UserClientFlowTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let withdrawnCount = OSAllocatedUnfairLock(initialState: 0)

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set("애니픽", forKey: "nickname")
    }

    deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    private func makeClient(_ stub: ClientStub) -> LiveUserClient {
        return LiveUserClient(
            client: stub.client,
            preferences: Preferences(defaults: defaults),
            onWithdrawn: { [withdrawnCount] in withdrawnCount.withLock { $0 += 1 } }
        )
    }

    @Test("W5·W6. 탈퇴 성공: PATCH api/setting/withdrawal → 닉네임 비우고 로그아웃 처리 1번")
    func withdrawsAndSignsOut() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        try await makeClient(stub).withdraw()

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/setting/withdrawal")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(defaults.string(forKey: "nickname") == "")
        #expect(withdrawnCount.withLock { $0 } == 1)
    }

    @Test(
        "W7. 거절·전송 실패면 닉네임을 두고 로그아웃하지 않는다",
        arguments: [
            (
                ClientStub.Reply.json(#"{"code":500,"value":"FAIL","errorValue":null}"#),
                WithdrawalError.rejected
            ),
            (.failure(.notConnectedToInternet), .transport(.offline)),
        ]
    )
    func keepsSessionOnFailure(reply: ClientStub.Reply, expected: WithdrawalError) async {
        let client = makeClient(ClientStub(reply))

        await #expect(throws: expected) {
            try await client.withdraw()
        }

        #expect(defaults.string(forKey: "nickname") == "애니픽")
        #expect(withdrawnCount.withLock { $0 } == 0)
    }

    @Test("닉네임 변경 성공이면 저장된 닉네임을 바꾼다, 거절이면 그대로")
    func savesNicknameOnlyOnSuccess() async throws {
        try await makeClient(
            ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))
        )
        .editNickname("새닉")
        #expect(defaults.string(forKey: "nickname") == "새닉")

        await #expect(throws: EditNicknameError.duplicated) {
            try await self.makeClient(
                ClientStub(.json(#"{"code":117,"value":"FAIL","errorValue":null}"#))
            )
            .editNickname("또닉")
        }
        #expect(defaults.string(forKey: "nickname") == "새닉")
    }

    @Test("저장된 이메일이 없으면 빈 문자열")
    func readsCachedEmail() {
        let client = makeClient(ClientStub(.json("{}")))
        #expect(client.cachedEmail() == "")
        defaults.set("a@b.c", forKey: "email")
        #expect(client.cachedEmail() == "a@b.c")
    }
}
