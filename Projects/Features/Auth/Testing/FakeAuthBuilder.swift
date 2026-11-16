import AuthInterface
import SwiftUI

/// 로그인 화면 대신 이름만 보여 준다 (다른 Feature의 Example·테스트용).
public struct FakeAuthBuilder: AuthBuilding {
    public init() {}

    public func make(_ route: AuthRoute) -> AnyView {
        return AnyView(Text("Auth: \(String(describing: route))"))
    }
}
