import ClientCore
import UserClientInterface
import os

/// 시나리오형 가짜. 결과·지연을 정해 두고 받은 요청을 기록한다 (Store 테스트·Example 앱).
public final class MockUserClient: UserClient {
    public struct Scenario: Sendable {
        public var nickname: String
        public var editNicknameResult: Result<Void, EditNicknameError>
        public var delay: Duration

        public init(
            nickname: String = "애니픽",
            editNicknameResult: Result<Void, EditNicknameError> = .success(()),
            delay: Duration = .zero
        ) {
            self.nickname = nickname
            self.editNicknameResult = editNicknameResult
            self.delay = delay
        }

        public static let success = Scenario()
        public static let duplicated = Scenario(editNicknameResult: .failure(.duplicated))
        public static let offline = Scenario(editNicknameResult: .failure(.transport(.offline)))
    }

    private let state: OSAllocatedUnfairLock<(scenario: Scenario, editedNicknames: [String])>

    public init(_ scenario: Scenario = .success) {
        state = OSAllocatedUnfairLock(initialState: (scenario, []))
    }

    /// `editNickname`으로 받은 값
    public var editedNicknames: [String] {
        return state.withLock { $0.editedNicknames }
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
}
