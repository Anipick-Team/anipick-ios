import Navigation

/// 이동 요청을 기록한다
public final class RecordingNavigator: Navigator {
    public enum Action: Equatable {
        case push(AnyHashable)
        case pop
        case popToRoot
        case present(AnyHashable)
        case dismiss
    }

    public private(set) var actions: [Action] = []

    public init() {}

    public func push(_ route: some Hashable & Sendable) {
        actions.append(.push(AnyHashable(route)))
    }

    public func pop() {
        actions.append(.pop)
    }

    public func popToRoot() {
        actions.append(.popToRoot)
    }

    public func present(_ route: some Hashable & Sendable) {
        actions.append(.present(AnyHashable(route)))
    }

    public func dismiss() {
        actions.append(.dismiss)
    }
}
