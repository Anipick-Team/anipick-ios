import RankingInterface
import SwiftUI

/// 랭킹 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeRankingBuilder: RankingBuilding {
    public init() {}

    public func make(_ route: RankingRoute) -> AnyView {
        return AnyView(Text("Ranking: \(String(describing: route))"))
    }
}
