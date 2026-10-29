import SwiftUI

/// 탐색 Feature(커뮤니티 포함)의 화면.
///
/// 아직 레거시인 화면(`communityBoard`·`communityPost`)도 미리 둔다. 이관하기 전까지는 App이 이 Route를 가로채
/// 레거시 화면을 보여 준다 (같은 Feature 안의 Strangler).
public enum ExploreRoute: Hashable, Sendable {
    /// 하단 "탐색" 탭 (작품 탐색 | 커뮤니티)
    case main
    /// 탐색 탭의 "커뮤니티" 하위 탭 내용 (탐색 화면 안에 들어간다)
    case communityBoards
    /// 애니 커뮤니티 게시판 (레거시 `AppRoute.community`)
    case communityBoard(
        seriesId: Int, animeTitle: String, coverImageUrl: String?, genreNames: [String])
    /// 커뮤니티 게시글 상세 (레거시 `AppRoute.communityDetail`)
    case communityPost(id: Int)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol ExploreBuilding {
    func make(_ route: ExploreRoute) -> AnyView
}

/// 다른 화면이 탐색 탭으로 넘기는 연도·분기 (레거시 `AppState.ExploreFilter`)
public struct PendingExploreFilter: Equatable, Sendable {
    public let year: String?
    public let season: String?

    public init(year: String?, season: String?) {
        self.year = year
        self.season = season
    }
}
