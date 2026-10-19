import SettingInterface
import SwiftUI

/// 설정 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeSettingBuilder: SettingBuilding {
    public init() {}

    public func make(_ route: SettingRoute) -> AnyView {
        return AnyView(Text("Setting: \(String(describing: route))"))
    }
}
