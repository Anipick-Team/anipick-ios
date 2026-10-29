import SwiftUI

/// 홈 Feature의 화면 (이관 전: App이 레거시 화면에 연결한다)
public enum HomeRoute: Hashable, Sendable {
    /// 검색 (레거시 `AppRoute.homeSearch`)
    case search
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol HomeBuilding {
    func make(_ route: HomeRoute) -> AnyView
}
