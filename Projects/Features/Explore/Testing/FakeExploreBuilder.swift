import ExploreInterface
import SwiftUI

/// 탐색 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeExploreBuilder: ExploreBuilding {
    public init() {}

    public func make(_ route: ExploreRoute) -> AnyView {
        return AnyView(Text("Explore: \(String(describing: route))"))
    }
}
