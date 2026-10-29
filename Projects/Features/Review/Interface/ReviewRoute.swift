import SwiftUI

/// 리뷰 Feature의 화면
public enum ReviewRoute: Hashable, Sendable {
    /// 리뷰 작성. `content`가 비어 있지 않으면 수정 화면이 된다
    case write(animeId: Int, rating: Double, content: String)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol ReviewBuilding {
    func make(_ route: ReviewRoute) -> AnyView
}
