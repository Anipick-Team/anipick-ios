import MetadataClientInterface
import Navigation
import RankingClientInterface
import RankingInterface
import SwiftUI

public struct RankingDependencies {
    public let rankingClient: any RankingClient
    public let metadataClient: any MetadataClient
    public let navigator: any Navigator

    public init(
        rankingClient: any RankingClient,
        metadataClient: any MetadataClient,
        navigator: any Navigator
    ) {
        self.rankingClient = rankingClient
        self.metadataClient = metadataClient
        self.navigator = navigator
    }
}

public struct RankingBuilder: RankingBuilding {
    private let dependencies: RankingDependencies

    public init(dependencies: RankingDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: RankingRoute) -> AnyView {
        switch route {
        case .main:
            let reducer = RankingReducer(
                rankingClient: dependencies.rankingClient,
                metadataClient: dependencies.metadataClient,
                navigator: dependencies.navigator
            )
            // 장르 목록은 화면을 만들 때 한 번 읽는다 (레거시 @State 초기값)
            let state = RankingReducer.State(
                genres: dependencies.metadataClient.cachedGenres().map(\.name)
            )
            return AnyView(RankingView(state: state, reducer: reducer))
        }
    }
}
