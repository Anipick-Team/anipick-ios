import SwiftUI

/// 홈 Feature의 화면
public enum HomeRoute: Hashable, Sendable {
    /// 검색 (레거시 `AppRoute.homeSearch`)
    case search
    /// 취향 추천 목록 (레거시 `AppRoute.recommend2`). animeId는 쓰지 않는다 (레거시 그대로)
    case recommendations(animeId: Int, animeTitle: String?)
    /// 최근 본 작품과 비슷한 작품 목록 (레거시 `AppRoute.recommendView`)
    case similarRecommendations(animeId: Int?)
    /// 공개 예정 목록 (레거시 `AppRoute.comingSoonDetail`)
    case comingSoon
    /// 요일별 신작 (레거시 `AppRoute.weekdayNewAnime`). day는 월=1 … 일=7, 범위 밖이면 오늘
    case weekdayNewAnime(day: Int)
    /// 최근 리뷰 목록 (레거시 `AppRoute.recentReview`)
    case recentReviews
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol HomeBuilding {
    func make(_ route: HomeRoute) -> AnyView
}
