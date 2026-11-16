import SwiftUI

/// 설정 Feature의 화면. 이관하는 대로 case를 늘린다.
public enum SettingRoute: Hashable, Sendable {
    /// 설정 메인
    case main
    case editNickname
    case withdrawal
    case editPassword
    case editEmail
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol SettingBuilding {
    func make(_ route: SettingRoute) -> AnyView
}
