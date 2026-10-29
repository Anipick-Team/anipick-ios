import SwiftUI

/// 홈 Feature의 화면
public enum HomeRoute: Hashable, Sendable {
    /// 검색 (레거시 `AppRoute.homeSearch`)
    case search
    /// 취향 추천 목록 (레거시 `AppRoute.recommend2`). animeId는 쓰지 않는다 (레거시 그대로)
    case recommendations(animeId: Int, animeTitle: String?)
    /// 최근 본 작품과 비슷한 작품 목록 (레거시 `AppRoute.recommendView`)
    case similarRecommendations(animeId: Int?)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol HomeBuilding {
    func make(_ route: HomeRoute) -> AnyView
}
