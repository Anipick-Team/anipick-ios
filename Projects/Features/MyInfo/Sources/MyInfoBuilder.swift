import Foundation
import MyInfoClientInterface
import MyInfoInterface
import Navigation
import ReviewClientInterface
import SwiftUI

public struct MyInfoDependencies {
    public let myInfoClient: any MyInfoClient
    public let reviewClient: any ReviewClient
    public let navigator: any Navigator
    /// 이 알림을 받으면 평가한 작품 첫 페이지를 다시 받는다 (App: 레거시 `.reloadRatedAnime`)
    public let ratedReviewsReloadNotification: Notification.Name?

    public init(
        myInfoClient: any MyInfoClient,
        reviewClient: any ReviewClient,
        navigator: any Navigator,
        ratedReviewsReloadNotification: Notification.Name? = nil
    ) {
        self.myInfoClient = myInfoClient
        self.reviewClient = reviewClient
        self.navigator = navigator
        self.ratedReviewsReloadNotification = ratedReviewsReloadNotification
    }
}

public struct MyInfoBuilder: MyInfoBuilding {
    private let dependencies: MyInfoDependencies

    public init(dependencies: MyInfoDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: MyInfoRoute) -> AnyView {
        switch route {
        case .watchList:
            return watchList(.watchList)
        case .watching:
            return watchList(.watching)
        case .finished:
            return watchList(.finished)
        case .likedAnimes:
            let reducer = LikedAnimesReducer(
                myInfoClient: dependencies.myInfoClient,
                navigator: dependencies.navigator
            )
            return AnyView(LikedAnimesView(state: LikedAnimesReducer.State(), reducer: reducer))
        case .ratedReviews:
            let reducer = RatedReviewsReducer(
                myInfoClient: dependencies.myInfoClient,
                reviewClient: dependencies.reviewClient,
                navigator: dependencies.navigator
            )
            return AnyView(
                RatedReviewsView(
                    state: RatedReviewsReducer.State(),
                    reducer: reducer,
                    reloadNotification: dependencies.ratedReviewsReloadNotification
                )
            )
        case .likedPersons:
            let reducer = LikedPersonsReducer(
                myInfoClient: dependencies.myInfoClient,
                navigator: dependencies.navigator
            )
            return AnyView(LikedPersonsView(state: LikedPersonsReducer.State(), reducer: reducer))
        }
    }

    private func watchList(_ status: WatchStatus) -> AnyView {
        let reducer = WatchListReducer(
            status: status,
            myInfoClient: dependencies.myInfoClient,
            navigator: dependencies.navigator
        )
        return AnyView(
            WatchListView(state: WatchListReducer.State(status: status), reducer: reducer))
    }
}
