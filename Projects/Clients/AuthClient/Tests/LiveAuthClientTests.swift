import AuthClientInterface
import Foundation
import Networking
import Storage
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

    @Test(
        "EL13. 이메일 로그인: 토큰 없이 POST api/users/login {email,password}. 성공하면 토큰·닉네임·이메일·sns 빈 값·userId 저장"
    )
    func emailLogin() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"reviewCompletedYn":true,"userId":42,"nickname":"애니","token":{"accessToken":"A","refreshToken":"R"}}}"#
            ))
        let defaults = UserDefaults(suiteName: "auth-\(UUID().uuidString)")!
        defaults.set("KAKAO", forKey: "sns")
        let stored = OSAllocatedUnfairLock(initialState: [String]())
        let client = LiveAuthClient(
            client: stub.client, onLoggedOut: {},
            storeTokens: { access, refresh in stored.withLock { $0 = [access, refresh] } },
            preferences: Preferences(defaults: defaults))

        let result = try await client.loginWithEmail(email: "a@b.co", password: "pw1!")

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/users/login")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(
            result
                == .success(
                    LoggedInUser(
                        userId: 42, nickname: "애니", hasAccessToken: true, reviewCompleted: true)))
        #expect(stored.withLock { $0 } == ["A", "R"])
        #expect(defaults.string(forKey: "nickname") == "애니")
        #expect(defaults.string(forKey: "email") == "a@b.co")
        #expect(defaults.string(forKey: "sns") == "")
        #expect(defaults.integer(forKey: "userId") == 42)
        guard
            case .json(let body) = LiveAuthClient.emailLoginEndpoint(
                email: "a@b.co", password: "pw1!"
            ).body
        else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let json =
            try JSONSerialization.jsonObject(with: try JSONEncoder().encode(body))
            as? [String: String]
        #expect(json == ["email": "a@b.co", "password": "pw1!"])
    }

    @Test(
        "EL13. 응답 코드를 결과로 바꾼다 (저장하지 않는다)",
        arguments: [
            (110, EmailLoginResult.invalidPasswordFormat), (101, .wrongCredentials),
            (104, .wrongCredentials),
            (106, .wrongCredentials), (105, .emptyPassword), (112, .accountNotFound),
            (132, .withdrawn),
            (102, .emptyEmail), (500, .unexpected(code: 500)),
        ]
    )
    func emailLoginCodes(code: Int, expected: EmailLoginResult) async throws {
        let stub = ClientStub(.json(#"{"code":\#(code),"value":"FAIL","errorValue":null}"#))
        let stored = OSAllocatedUnfairLock(initialState: 0)
        let client = LiveAuthClient(
            client: stub.client, onLoggedOut: {},
            storeTokens: { _, _ in stored.withLock { $0 += 1 } })

        #expect(try await client.loginWithEmail(email: "a", password: "b") == expected)
        #expect(stored.withLock { $0 } == 0)
    }

    @Test("EL13. 200인데 result가 없으면 missingResult")
    func emailLoginMissingResult() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        let result = try await LiveAuthClient(client: stub.client, onLoggedOut: {})
            .loginWithEmail(email: "a", password: "b")

        #expect(result == .missingResult)
    }

    @Test(
        "SU11. 가입: 토큰 없이 POST api/users/signup {email,password,termsAndConditions}. 200이면 토큰·닉네임·이메일 저장, sns 빈 값, userId 지움"
    )
    func signup() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"nickname":null,"token":{"accessToken":"A","refreshToken":"R"}}}"#
            ))
        let defaults = UserDefaults(suiteName: "auth-\(UUID().uuidString)")!
        defaults.set(9, forKey: "userId")
        let stored = OSAllocatedUnfairLock(initialState: [String]())
        let client = LiveAuthClient(
            client: stub.client, onLoggedOut: {},
            storeTokens: { access, refresh in stored.withLock { $0 = [access, refresh] } },
            preferences: Preferences(defaults: defaults))

        let result = try await client.signupWithEmail(
            email: "a@b.co", password: "pw", agreedToTerms: true)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/users/signup")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(result == .success)
        #expect(stored.withLock { $0 } == ["A", "R"])
        #expect(defaults.string(forKey: "nickname") == "nickname - null")
        #expect(defaults.string(forKey: "email") == "a@b.co")
        #expect(defaults.string(forKey: "sns") == "")
        #expect(defaults.object(forKey: "userId") == nil)
        guard
            case .json(let body) = LiveAuthClient.signupEndpoint(
                email: "a", password: "b", agreedToTerms: true
            ).body
        else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let json =
            try JSONSerialization.jsonObject(with: try JSONEncoder().encode(body)) as? [String: Any]
        #expect(json?["email"] as? String == "a")
        #expect(json?["password"] as? String == "b")
        #expect(json?["termsAndConditions"] as? Bool == true)
    }

    @Test("SU11. 109는 duplicatedEmail, 그 밖은 unexpected (저장하지 않음)")
    func signupCodes() async throws {
        let stored = OSAllocatedUnfairLock(initialState: 0)
        for (code, expected) in [
            (109, EmailSignupResult.duplicatedEmail), (500, .unexpected(code: 500)),
        ] {
            let stub = ClientStub(.json(#"{"code":\#(code),"value":"FAIL","errorValue":null}"#))
            let client = LiveAuthClient(
                client: stub.client, onLoggedOut: {},
                storeTokens: { _, _ in stored.withLock { $0 += 1 } })

            #expect(
                try await client.signupWithEmail(email: "a", password: "b", agreedToTerms: true)
                    == expected)
        }
        #expect(stored.withLock { $0 } == 0)
    }

    @Test(
        "FP13. 비밀번호 찾기: 보내기·확인 POST, 재설정 PATCH, 토큰 없음. 인증 성공 시 이메일 저장")
    func findPassword() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))
        let defaults = UserDefaults(suiteName: "auth-\(UUID().uuidString)")!
        let client = LiveAuthClient(
            client: stub.client, onLoggedOut: {}, preferences: Preferences(defaults: defaults))

        #expect(try await client.sendVerificationCode(email: "a@b.co") == .sent)
        #expect(try await client.verifyCode(email: "a@b.co", code: "1234") == .verified)
        #expect(try await client.resetPassword(newPassword: "n", confirmation: "c"))

        #expect(stub.requests.map(\.httpMethod) == ["POST", "POST", "PATCH"])
        #expect(
            stub.requests.map { $0.url?.path() }
                == ["/api/auth/email/send", "/api/auth/email/verify", "/api/auth/password/reset"])
        #expect(stub.requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == nil })
        #expect(defaults.string(forKey: "email") == "a@b.co")
    }

    @Test("FP13. 응답 코드를 결과로 바꾼다")
    func findPasswordCodes() async throws {
        for (code, send, verify) in [
            (112, SendCodeResult.accountNotFound, VerifyCodeResult.unexpected(code: 112)),
            (103, .invalidEmail, .unexpected(code: 103)),
            (102, .emptyEmail, .unexpected(code: 102)),
            (113, .unexpected(code: 113), .emptyCode), (114, .unexpected(code: 114), .wrongCode),
            (115, .unexpected(code: 115), .expired),
        ] {
            let stub = ClientStub(.json(#"{"code":\#(code),"value":"FAIL","errorValue":null}"#))
            let client = LiveAuthClient(client: stub.client, onLoggedOut: {})

            #expect(try await client.sendVerificationCode(email: "a") == send)
            #expect(try await client.verifyCode(email: "a", code: "b") == verify)
            #expect(try await client.resetPassword(newPassword: "n", confirmation: "c") == false)
        }
    }
}
