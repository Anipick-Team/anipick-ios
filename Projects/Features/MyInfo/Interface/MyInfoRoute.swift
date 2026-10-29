import SwiftUI

/// 마이페이지 Feature의 화면. 이관하는 대로 case를 늘린다.
public enum MyInfoRoute: Hashable, Sendable {
    /// 하단 "마이" 탭
    case main
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
    /// 내 콘텐츠 (내 게시글·내 댓글)
    case myContent
}

/// 하단 탭. 내 콘텐츠 화면이 자기 아래에 탭 바를 따로 그리고, 누르면 App이 그 탭으로 보낸다
public enum MainTab: Hashable, Sendable, CaseIterable {
    case home
    case ranking
    case explore
    case myInfo
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol MyInfoBuilding {
    func make(_ route: MyInfoRoute) -> AnyView
}
