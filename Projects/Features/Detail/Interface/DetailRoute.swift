import SwiftUI

/// 애니 상세 Feature의 화면.
public enum DetailRoute: Hashable, Sendable {
    /// 애니 상세 (레거시 `AppRoute.animeDetail`)
    case anime(id: Int)
    /// 성우(인물) 상세 (레거시 `AppRoute.voiceActorDetail`)
    case voiceActor(id: Int)
    /// 제작사 상세 (레거시 `AppRoute.producerDetail`)
    case producer(id: Int)
    /// 관련 작품 (레거시 `AppRoute.seriesDetail`)
    case series(animeId: Int, animeTitle: String)
    /// 함께 볼만한 작품 (레거시 `AppRoute.recommend`)
    case recommendations(animeId: Int, animeTitle: String)
    /// 캐릭터·성우진 (레거시 `AppRoute.characterAndVoiceActorDetail`)
    case cast(animeId: Int)
}

/// App이 구현을 주입한다 (TMA: 다른 Feature는 이 프로토콜만 안다).
@MainActor
public protocol DetailBuilding {
    func make(_ route: DetailRoute) -> AnyView
}
