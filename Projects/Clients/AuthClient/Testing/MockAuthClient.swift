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
