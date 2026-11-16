import Navigation
import Observation
import SwiftUI

/// Example 앱의 이동. `NavigationStack(path:)`에 연결한다 (모달은 무시)
@Observable
public final class ExampleNavigator: Navigator {
    public var path = NavigationPath()

    public init() {}

    public func push(_ route: some Hashable & Sendable) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    public func popToRoot() {
        path = NavigationPath()
    }

    public func present(_ route: some Hashable & Sendable) {}

    public func dismiss() {}
}
