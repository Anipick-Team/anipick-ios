import DetailInterface
import SwiftUI

/// 상세 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeDetailBuilder: DetailBuilding {
    public init() {}

    public func make(_ route: DetailRoute) -> AnyView {
        return AnyView(Text("Detail: \(String(describing: route))"))
    }
}
