import Analytics
import Foundation
import HomeClientInterface
import HomeInterface
import Navigation
import ReviewClientInterface
import SwiftUI

public struct HomeDependencies {
    public let homeClient: any HomeClient
    public let reviewClient: any ReviewClient
    public let navigator: any Navigator
    public let analytics: any AnalyticsTracking
    /// 이 기기에 저장된 닉네임 (없으면 "--")
    public let cachedNickname: @MainActor () -> String
    /// 이미지 id를 받을 주소 (`{서버}api/image/{id}`, 인증 필요)
    public let imageURL: @Sendable (Int) -> URL

    public init(
        homeClient: any HomeClient,
        reviewClient: any ReviewClient,
        navigator: any Navigator,
        analytics: any AnalyticsTracking,
        cachedNickname: @escaping @MainActor () -> String,
        imageURL: @escaping @Sendable (Int) -> URL
    ) {
        self.homeClient = homeClient
        self.reviewClient = reviewClient
        self.navigator = navigator
        self.analytics = analytics
        self.cachedNickname = cachedNickname
        self.imageURL = imageURL
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
        case .recentReviews:
            return AnyView(
                RecentReviewsView(
                    state: RecentReviewsReducer.State(),
                    reducer: RecentReviewsReducer(
                        reviewClient: dependencies.reviewClient, navigator: dependencies.navigator),
                    imageURL: dependencies.imageURL))
        case .search:
            return AnyView(
                HomeSearchView(
                    state: HomeSearchReducer.State(),
                    reducer: HomeSearchReducer(
                        homeClient: dependencies.homeClient, navigator: dependencies.navigator,
                        analytics: dependencies.analytics)))
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
