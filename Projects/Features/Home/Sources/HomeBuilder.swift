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
    /// 마지막으로 본 애니 id (없으면 0)
    public let lastVisitedAnimeId: @MainActor () -> Int
    /// 랭킹 탭으로 (탭 구조는 App이 안다)
    public let showRanking: @MainActor () -> Void
    /// 탐색 탭으로 연도·분기를 넘긴다
    public let showExplore: @MainActor (_ year: Int, _ season: Int) -> Void

    public init(
        homeClient: any HomeClient,
        reviewClient: any ReviewClient,
        navigator: any Navigator,
        analytics: any AnalyticsTracking,
        cachedNickname: @escaping @MainActor () -> String,
        imageURL: @escaping @Sendable (Int) -> URL,
        lastVisitedAnimeId: @escaping @MainActor () -> Int = { 0 },
        showRanking: @escaping @MainActor () -> Void = {},
        showExplore: @escaping @MainActor (_ year: Int, _ season: Int) -> Void = { _, _ in }
    ) {
        self.homeClient = homeClient
        self.reviewClient = reviewClient
        self.navigator = navigator
        self.analytics = analytics
        self.cachedNickname = cachedNickname
        self.imageURL = imageURL
        self.lastVisitedAnimeId = lastVisitedAnimeId
        self.showRanking = showRanking
        self.showExplore = showExplore
    }
}

public struct HomeBuilder: HomeBuilding {
    private let dependencies: HomeDependencies

    public init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: HomeRoute) -> AnyView {
        switch route {
        case .main:
            let reducer = HomeMainReducer(
                homeClient: dependencies.homeClient,
                navigator: dependencies.navigator,
                cachedNickname: dependencies.cachedNickname,
                lastVisitedAnimeId: dependencies.lastVisitedAnimeId,
                showRanking: dependencies.showRanking,
                showExplore: dependencies.showExplore
            )
            return AnyView(
                HomeMainView(
                    state: HomeMainReducer.State(selectedWeekday: .of(Date())), reducer: reducer))
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
