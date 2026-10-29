import SwiftUI

/// 마이페이지 Feature의 화면. 이관하는 대로 case를 늘린다.
public enum MyInfoRoute: Hashable, Sendable {
    /// 볼 애니
    case watchList
    /// 보는 중
    case watching
    /// 다 본 애니
    case finished
    /// 좋아요한 작품
    case likedAnimes
    /// 좋아요한 인물
    case likedPersons
    /// 평가한 작품
    case ratedReviews
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol MyInfoBuilding {
    func make(_ route: MyInfoRoute) -> AnyView
}
