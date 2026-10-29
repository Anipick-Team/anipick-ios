import HomeInterface
import SwiftUI

/// 홈 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeHomeBuilder: HomeBuilding {
    public init() {}

    public func make(_ route: HomeRoute) -> AnyView {
        return AnyView(Text("Home: \(String(describing: route))"))
    }
}
