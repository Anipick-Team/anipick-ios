import Foundation
import HomeClientInterface
import HomeInterface
import Navigation
import SwiftUI

public struct HomeDependencies {
    public let homeClient: any HomeClient
    public let navigator: any Navigator
    /// 이 기기에 저장된 닉네임 (없으면 "--")
    public let cachedNickname: @MainActor () -> String

    public init(
        homeClient: any HomeClient,
        navigator: any Navigator,
        cachedNickname: @escaping @MainActor () -> String
    ) {
        self.homeClient = homeClient
        self.navigator = navigator
        self.cachedNickname = cachedNickname
    }
}

public struct HomeBuilder: HomeBuilding {
    private let dependencies: HomeDependencies

    public init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: HomeRoute) -> AnyView {
        switch route {
        case .recommendations(_, let animeTitle):
            return makeRecommendations(.forYou(animeTitle: animeTitle))
        case .similarRecommendations(let animeId):
            return makeRecommendations(.similar(animeId: animeId))
        case .comingSoon:
            return AnyView(
                ComingSoonView(
                    state: ComingSoonReducer.State(),
                    reducer: ComingSoonReducer(
                        homeClient: dependencies.homeClient, navigator: dependencies.navigator)))
        case .weekdayNewAnime(let day):
            return AnyView(
                WeekdayNewAnimeView(
                    state: WeekdayNewAnimeReducer.State(
                        day: WeekdayNewAnimeDay(rawValue: day) ?? .of(Date())),
                    reducer: WeekdayNewAnimeReducer(
                        homeClient: dependencies.homeClient, navigator: dependencies.navigator)))
        case .search:
            // 아직 레거시 화면 — App이 가로챈다
            assertionFailure("레거시 화면 Route가 Home 빌더로 왔다: \(route)")
            return AnyView(EmptyView())
        }
    }

    private func makeRecommendations(_ kind: RecommendationListReducer.Kind) -> AnyView {
        let reducer = RecommendationListReducer(
            homeClient: dependencies.homeClient, navigator: dependencies.navigator)
        return AnyView(
            RecommendationListView(
                state: RecommendationListReducer.State(
                    kind: kind, nickname: dependencies.cachedNickname()),
                reducer: reducer))
    }
}
