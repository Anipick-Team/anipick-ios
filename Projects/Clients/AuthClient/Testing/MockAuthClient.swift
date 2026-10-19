import AuthClientInterface
import os

/// 로그아웃 호출을 기록한다 (Store 테스트·Example 앱).
public final class MockAuthClient: AuthClient {
    private let count = OSAllocatedUnfairLock(initialState: 0)

    public init() {}

    /// `logout` 호출 횟수
    public var logoutCount: Int {
        return count.withLock { $0 }
    }

    public func logout() async {
        count.withLock { $0 += 1 }
    }
}
