import AuthClientInterface
import os

/// 로그아웃 호출을 기록한다 (Store 테스트·Example 앱).
public final class MockAuthClient: AuthClient {
    private let counts = OSAllocatedUnfairLock(initialState: (logout: 0, immediate: 0))

    public init() {}

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
