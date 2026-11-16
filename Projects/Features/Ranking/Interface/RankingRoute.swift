import SwiftUI

/// 랭킹 Feature의 화면
public enum RankingRoute: Hashable, Sendable {
    /// 하단 "랭킹" 탭
    case main
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol RankingBuilding {
    func make(_ route: RankingRoute) -> AnyView
}
