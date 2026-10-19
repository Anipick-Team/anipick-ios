import Navigation
import SettingInterface
import SwiftUI
import UserClientInterface

public struct SettingDependencies {
    public let userClient: any UserClient
    public let navigator: any Navigator

    public init(userClient: any UserClient, navigator: any Navigator) {
        self.userClient = userClient
        self.navigator = navigator
    }
}

public struct SettingBuilder: SettingBuilding {
    private let dependencies: SettingDependencies

    public init(dependencies: SettingDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: SettingRoute) -> AnyView {
        switch route {
        case .editNickname:
            let reducer = EditNicknameReducer(
                userClient: dependencies.userClient,
                navigator: dependencies.navigator
            )
            let state = EditNicknameReducer.State(
                currentNickname: dependencies.userClient.cachedNickname()
            )
            return AnyView(EditNicknameView(state: state, reducer: reducer))
        }
    }
}
