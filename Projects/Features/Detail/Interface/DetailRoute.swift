import SwiftUI

/// 애니 상세 Feature의 화면 (이관 전: App이 레거시 화면에 연결한다)
public enum DetailRoute: Hashable, Sendable {
    /// 애니 상세 (레거시 `AppRoute.animeDetail`)
    case anime(id: Int)
    /// 성우(인물) 상세 (레거시 `AppRoute.voiceActorDetail`)
    case voiceActor(id: Int)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol DetailBuilding {
    func make(_ route: DetailRoute) -> AnyView
}
