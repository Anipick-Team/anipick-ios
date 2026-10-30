import ClientCore
import UserClientInterface
import os

/// 시나리오형 가짜. 결과·지연을 정해 두고 받은 요청을 기록한다 (Store 테스트·Example 앱).
public final class MockUserClient: UserClient {
    public struct Scenario: Sendable {
        public var nickname: String
        public var email: String
        public var snsAccount: String
        public var editNicknameResult: Result<Void, EditNicknameError>
        public var withdrawalResult: Result<Void, WithdrawalError>
        public var editPasswordResult: Result<Void, EditPasswordError>
        public var editEmailResult: Result<Void, EditEmailError>
        public var delay: Duration

        public init(
            nickname: String = "애니픽",
            email: String = "anipick@example.com",
            snsAccount: String = "",
            editNicknameResult: Result<Void, EditNicknameError> = .success(()),
            withdrawalResult: Result<Void, WithdrawalError> = .success(()),
            editPasswordResult: Result<Void, EditPasswordError> = .success(()),
            editEmailResult: Result<Void, EditEmailError> = .success(()),
            delay: Duration = .zero
        ) {
            self.nickname = nickname
            self.email = email
            self.snsAccount = snsAccount
            self.editNicknameResult = editNicknameResult
            self.withdrawalResult = withdrawalResult
            self.editPasswordResult = editPasswordResult
            self.editEmailResult = editEmailResult
            self.delay = delay
        }

        public static let success = Scenario()
        public static let duplicated = Scenario(editNicknameResult: .failure(.duplicated))
        public static let offline = Scenario(editNicknameResult: .failure(.transport(.offline)))
    }

    public struct PasswordChange: Equatable, Sendable {
        public let current: String
        public let new: String
        public let confirmation: String

        public init(current: String, new: String, confirmation: String) {
            self.current = current
            self.new = new
            self.confirmation = confirmation
        }
    }

    private struct State {
        var scenario: Scenario
        var editedNicknames: [String] = []
        var withdrawalCount = 0
        var editedPasswords: [PasswordChange] = []
        var editedEmails: [EmailChange] = []
    }

    public struct EmailChange: Equatable, Sendable {
        public let newEmail: String
        public let password: String

        public init(newEmail: String, password: String) {
            self.newEmail = newEmail
            self.password = password
        }
    }

    /// `editEmail`로 받은 값
    public var editedEmails: [EmailChange] {
        return state.withLock { $0.editedEmails }
    }

    public func editEmail(newEmail: String, password: String) async throws(EditEmailError) {
        let scenario = state.withLock {
            $0.editedEmails.append(EmailChange(newEmail: newEmail, password: password))
            return $0.scenario
        }
        try? await Task.sleep(for: scenario.delay)
        try scenario.editEmailResult.get()
        state.withLock { $0.scenario.email = newEmail }
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(_ scenario: Scenario = .success) {
        state = OSAllocatedUnfairLock(initialState: State(scenario: scenario))
    }

    /// `editNickname`으로 받은 값
    public var editedNicknames: [String] {
        return state.withLock { $0.editedNicknames }
    }

    /// `withdraw` 호출 횟수
    public var withdrawalCount: Int {
        return state.withLock { $0.withdrawalCount }
    }

    /// `editPassword`로 받은 값
    public var editedPasswords: [PasswordChange] {
        return state.withLock { $0.editedPasswords }
    }

    public func cachedNickname() -> String {
        return state.withLock { $0.scenario.nickname }
    }

    public func editNickname(_ nickname: String) async throws(EditNicknameError) {
        let scenario = state.withLock {
            $0.editedNicknames.append(nickname)
            return $0.scenario
        }
        try? await Task.sleep(for: scenario.delay)
        try scenario.editNicknameResult.get()
        state.withLock { $0.scenario.nickname = nickname }
    }

    public func cachedEmail() -> String {
        return state.withLock { $0.scenario.email }
    }

    public func cachedSNSAccount() -> String {
        return state.withLock { $0.scenario.snsAccount }
    }

    public func withdraw() async throws(WithdrawalError) {
        let scenario = state.withLock {
            $0.withdrawalCount += 1
            return $0.scenario
        }
        try? await Task.sleep(for: scenario.delay)
        try scenario.withdrawalResult.get()
        state.withLock { $0.scenario.nickname = "" }
    }

    public func editPassword(
        current: String,
        new: String,
        confirmation: String
    ) async throws(EditPasswordError) {
        let change = PasswordChange(current: current, new: new, confirmation: confirmation)
        let scenario = state.withLock {
            $0.editedPasswords.append(change)
            return $0.scenario
        }
        try? await Task.sleep(for: scenario.delay)
        try scenario.editPasswordResult.get()
    }
}
