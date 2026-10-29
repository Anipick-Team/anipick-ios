import CommunityClientInterface
import ExploreClientInterface
import ExploreInterface
import MetadataClientInterface
import Navigation
import SwiftUI

public struct ExploreDependencies {
    public let communityClient: any CommunityClient
    public let exploreClient: any ExploreClient
    public let metadataClient: any MetadataClient
    public let navigator: any Navigator
    /// 다른 화면이 넘겨 둔 연도·분기를 꺼낸다 (App: 레거시 `AppState.consumeExploreFilter`)
    public let consumePendingFilter: @MainActor @Sendable () -> PendingExploreFilter?
    /// 넘겨 둔 값이 바뀔 때마다 알린다 (탐색 탭이 이미 보이는 중일 때)
    public let pendingFilterUpdates: @MainActor () -> AsyncStream<Void>

    public init(
        communityClient: any CommunityClient,
        exploreClient: any ExploreClient,
        metadataClient: any MetadataClient,
        navigator: any Navigator,
        consumePendingFilter: @escaping @MainActor @Sendable () -> PendingExploreFilter? = { nil },
        pendingFilterUpdates: @escaping @MainActor () -> AsyncStream<Void> = {
            AsyncStream { $0.finish() }
        }
    ) {
        self.communityClient = communityClient
        self.exploreClient = exploreClient
        self.metadataClient = metadataClient
        self.navigator = navigator
        self.consumePendingFilter = consumePendingFilter
        self.pendingFilterUpdates = pendingFilterUpdates
    }
}

public struct ExploreBuilder: ExploreBuilding {
    private let dependencies: ExploreDependencies

    public init(dependencies: ExploreDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: ExploreRoute) -> AnyView {
        switch route {
        case .main:
            let reducer = ExploreReducer(
                exploreClient: dependencies.exploreClient,
                metadataClient: dependencies.metadataClient,
                navigator: dependencies.navigator,
                consumePendingFilter: dependencies.consumePendingFilter
            )
            // 메타데이터는 화면을 만들 때 읽는다 (레거시 ViewModel 초기값)
            let metadata = dependencies.metadataClient
            let state = ExploreReducer.State(
                genres: metadata.cachedGenres().map(\.name),
                years: metadata.cachedSeasonYears().map(String.init),
                types: metadata.cachedTypes()
            )
            return AnyView(
                ExploreView(
                    state: state,
                    reducer: reducer,
                    pendingFilterUpdates: dependencies.pendingFilterUpdates
                ) {
                    make(.communityBoards)
                }
            )
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
