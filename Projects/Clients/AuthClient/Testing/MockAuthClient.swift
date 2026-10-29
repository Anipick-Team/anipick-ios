import AuthClientInterface
import ClientCore
import os

/// 로그인 결과를 정해 두고 호출을 기록한다 (Store 테스트·Example 앱).
public final class MockAuthClient: AuthClient {
    public struct EmailLogin: Equatable, Sendable {
        public let email: String
        public let password: String

        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }

    private let counts = OSAllocatedUnfairLock(initialState: (logout: 0, immediate: 0))
    private let logins = OSAllocatedUnfairLock(initialState: [EmailLogin]())
    private let emailLoginResult: Result<EmailLoginResult, TransportError>
    private let signupResult: Result<EmailSignupResult, TransportError>
    private let signups = OSAllocatedUnfairLock(initialState: [Signup]())

    public struct Signup: Equatable, Sendable {
        public let email: String
        public let password: String
        public let agreedToTerms: Bool

        public init(email: String, password: String, agreedToTerms: Bool) {
            self.email = email
            self.password = password
            self.agreedToTerms = agreedToTerms
        }
    }

    public init(
        emailLoginResult: Result<EmailLoginResult, TransportError> = .success(
            .success(
                LoggedInUser(
                    userId: 1, nickname: "애니픽", hasAccessToken: true, reviewCompleted: true))),
        signupResult: Result<EmailSignupResult, TransportError> = .success(.success)
    ) {
        self.emailLoginResult = emailLoginResult
        self.signupResult = signupResult
    }

    /// 비밀번호 찾기 결과 (테스트가 바꾼다)
    public struct FindPassword: Sendable {
        public var send: Result<SendCodeResult, TransportError>
        public var verify: Result<VerifyCodeResult, TransportError>
        public var reset: Result<Bool, TransportError>

        public init(
            send: Result<SendCodeResult, TransportError> = .success(.sent),
            verify: Result<VerifyCodeResult, TransportError> = .success(.verified),
            reset: Result<Bool, TransportError> = .success(true)
        ) {
            self.send = send
            self.verify = verify
            self.reset = reset
        }
    }

    public enum FindPasswordCall: Equatable, Sendable {
        case send(email: String)
        case verify(email: String, code: String)
        case reset(newPassword: String, confirmation: String)
    }

    private let findPasswordState = OSAllocatedUnfairLock(
        initialState: (scenario: FindPassword(), calls: [FindPasswordCall]()))

    public var findPasswordScenario: FindPassword {
        get { findPasswordState.withLock { $0.scenario } }
        set { findPasswordState.withLock { $0.scenario = newValue } }
    }

    public var findPasswordCalls: [FindPasswordCall] {
        return findPasswordState.withLock { $0.calls }
    }

    public func sendVerificationCode(email: String) async throws(TransportError) -> SendCodeResult {
        return try findPasswordState.withLock {
            $0.calls.append(.send(email: email))
            return $0.scenario.send
        }
        .get()
    }

    public func verifyCode(email: String, code: String) async throws(TransportError)
        -> VerifyCodeResult
    {
        return try findPasswordState.withLock {
            $0.calls.append(.verify(email: email, code: code))
            return $0.scenario.verify
        }
        .get()
    }

    public func resetPassword(newPassword: String, confirmation: String)
        async throws(TransportError)
        -> Bool
    {
        return try findPasswordState.withLock {
            $0.calls.append(.reset(newPassword: newPassword, confirmation: confirmation))
            return $0.scenario.reset
        }
        .get()
    }

    public var emailSignups: [Signup] {
        return signups.withLock { $0 }
    }

    public func signupWithEmail(
        email: String,
        password: String,
        agreedToTerms: Bool
    ) async throws(TransportError) -> EmailSignupResult {
        signups.withLock {
            $0.append(Signup(email: email, password: password, agreedToTerms: agreedToTerms))
        }
        return try signupResult.get()
    }

    public var emailLogins: [EmailLogin] {
        return logins.withLock { $0 }
    }

    public func loginWithEmail(
        email: String,
        password: String
    ) async throws(TransportError) -> EmailLoginResult {
        logins.withLock { $0.append(EmailLogin(email: email, password: password)) }
        return try emailLoginResult.get()
    }

    /// `logout` 호출 횟수
    public var logoutCount: Int {
        return counts.withLock { $0.logout }
    }

    /// `logoutImmediately` 호출 횟수
    public var immediateLogoutCount: Int {
        return counts.withLock { $0.immediate }
    }

    public func logout() async {
        counts.withLock { $0.logout += 1 }
    }

    public func logoutImmediately() async {
        counts.withLock { $0.immediate += 1 }
    }
}
