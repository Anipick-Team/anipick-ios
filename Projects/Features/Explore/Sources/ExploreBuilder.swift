import CommunityClientInterface
import ExploreInterface
import Navigation
import SwiftUI

public struct ExploreDependencies {
    public let communityClient: any CommunityClient
    public let navigator: any Navigator

    public init(communityClient: any CommunityClient, navigator: any Navigator) {
        self.communityClient = communityClient
        self.navigator = navigator
    }
}

public struct ExploreBuilder: ExploreBuilding {
    private let dependencies: ExploreDependencies

    public init(dependencies: ExploreDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: ExploreRoute) -> AnyView {
        switch route {
        case .communityBoards:
            let reducer = CommunityBoardsReducer(
                communityClient: dependencies.communityClient,
                navigator: dependencies.navigator
            )
            return AnyView(
                CommunityBoardsView(state: CommunityBoardsReducer.State(), reducer: reducer))
        case .communityBoard, .communityPost:
            // 아직 레거시 화면 — App이 가로챈다
            assertionFailure("레거시 화면 Route가 Explore 빌더로 왔다: \(route)")
            return AnyView(EmptyView())
        }
    }
}
