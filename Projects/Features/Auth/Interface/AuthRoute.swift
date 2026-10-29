import SwiftUI

/// 로그인·가입 Feature의 화면.
///
/// 아직 레거시인 화면(`findPassword`·`preferenceSelection`)도 미리 둔다. 이관하기 전까지는 App이 이 두 Route를 가로채
/// 레거시 화면을 보여 준다 (같은 Feature 안의 Strangler).
public enum AuthRoute: Hashable, Sendable {
    case emailLogin
    case emailSignup
    case findPassword
    /// "로그인에 문제가 있으신가요?" (내용 없는 화면)
    case loginProblem
    /// 가입 후 취향 선택 (온보딩)
    case preferenceSelection
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol AuthBuilding {
    func make(_ route: AuthRoute) -> AnyView
}
