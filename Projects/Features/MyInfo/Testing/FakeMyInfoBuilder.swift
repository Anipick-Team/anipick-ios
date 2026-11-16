import MyInfoInterface
import SwiftUI

/// 마이페이지 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeMyInfoBuilder: MyInfoBuilding {
    public init() {}

    public func make(_ route: MyInfoRoute) -> AnyView {
        return AnyView(Text("MyInfo: \(String(describing: route))"))
    }
}
