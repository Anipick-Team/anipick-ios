import Analytics
import Foundation
import Navigation
import ReviewClientInterface
import ReviewInterface
import SwiftUI

public struct ReviewDependencies {
    public let reviewClient: any ReviewClient
    public let navigator: any Navigator
    public let analytics: any AnalyticsTracking
    /// 커뮤니티 가이드라인 외부 링크
    public let openURL: @MainActor @Sendable (URL) -> Void
    /// 리뷰 저장 후 (App: 레거시 `.reloadRatedAnime` 알림)
    public let onReviewWritten: @Sendable () async -> Void

    public init(
        reviewClient: any ReviewClient,
        navigator: any Navigator,
        analytics: any AnalyticsTracking,
        openURL: @escaping @MainActor @Sendable (URL) -> Void = { _ in },
        onReviewWritten: @escaping @Sendable () async -> Void = {}
    ) {
        self.reviewClient = reviewClient
        self.navigator = navigator
        self.analytics = analytics
        self.openURL = openURL
        self.onReviewWritten = onReviewWritten
    }
}

public struct ReviewBuilder: ReviewBuilding {
    private let dependencies: ReviewDependencies

    public init(dependencies: ReviewDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: ReviewRoute) -> AnyView {
        switch route {
        case .write(let animeId, let rating, let content):
            let reducer = WriteReviewReducer(
                reviewClient: dependencies.reviewClient,
                navigator: dependencies.navigator,
                analytics: dependencies.analytics,
                openURL: dependencies.openURL,
                onReviewWritten: dependencies.onReviewWritten
            )
            let state = WriteReviewReducer.State(animeId: animeId, rating: rating, content: content)
            return AnyView(WriteReviewView(state: state, reducer: reducer))
        }
    }
}
