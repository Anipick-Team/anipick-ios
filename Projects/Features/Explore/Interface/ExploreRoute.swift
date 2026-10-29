import SwiftUI

/// 탐색 Feature(커뮤니티 포함)의 화면 (이관 전: App이 레거시 화면에 연결한다)
public enum ExploreRoute: Hashable, Sendable {
    /// 커뮤니티 게시글 상세 (레거시 `AppRoute.communityDetail`)
    case communityPost(id: Int)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol ExploreBuilding {
    func make(_ route: ExploreRoute) -> AnyView
}
