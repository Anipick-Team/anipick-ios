import DetailClientInterface
import DetailInterface
import Navigation
import SwiftUI

public struct DetailDependencies {
    public let detailClient: any DetailClient
    public let navigator: any Navigator

    public init(detailClient: any DetailClient, navigator: any Navigator) {
        self.detailClient = detailClient
        self.navigator = navigator
    }
}

public struct DetailBuilder: DetailBuilding {
    private let dependencies: DetailDependencies

    public init(dependencies: DetailDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: DetailRoute) -> AnyView {
        switch route {
        case .series(let animeId, let animeTitle):
            return makeList(.series, animeId: animeId, animeTitle: animeTitle)
        case .recommendations(let animeId, let animeTitle):
            return makeList(.recommendations, animeId: animeId, animeTitle: animeTitle)
        case .producer(let id):
            return AnyView(
                ProducerView(
                    state: ProducerReducer.State(studioId: id),
                    reducer: ProducerReducer(
                        detailClient: dependencies.detailClient, navigator: dependencies.navigator))
            )
        case .cast(let animeId):
            return AnyView(
                CastView(
                    state: CastReducer.State(animeId: animeId),
                    reducer: CastReducer(
                        detailClient: dependencies.detailClient, navigator: dependencies.navigator))
            )
        case .anime, .voiceActor:
            // 아직 레거시 화면 — App이 가로챈다
            assertionFailure("레거시 화면 Route가 Detail 빌더로 왔다: \(route)")
            return AnyView(EmptyView())
        }
    }

    private func makeList(_ kind: AnimeListReducer.Kind, animeId: Int, animeTitle: String)
        -> AnyView
    {
        let reducer = AnimeListReducer(
            detailClient: dependencies.detailClient, navigator: dependencies.navigator)
        return AnyView(
            AnimeListView(
                state: AnimeListReducer.State(kind: kind, animeId: animeId, animeTitle: animeTitle),
                reducer: reducer))
    }
}
