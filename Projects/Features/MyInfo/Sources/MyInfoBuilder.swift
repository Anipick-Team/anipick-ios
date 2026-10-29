import MyInfoClientInterface
import MyInfoInterface
import Navigation
import SwiftUI

public struct MyInfoDependencies {
    public let myInfoClient: any MyInfoClient
    public let navigator: any Navigator

    public init(myInfoClient: any MyInfoClient, navigator: any Navigator) {
        self.myInfoClient = myInfoClient
        self.navigator = navigator
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
