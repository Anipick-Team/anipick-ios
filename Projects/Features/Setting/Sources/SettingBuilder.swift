import AuthClientInterface
import Navigation
import SettingInterface
import SwiftUI
import UserClientInterface

public struct SettingDependencies {
    public let userClient: any UserClient
    public let authClient: any AuthClient
    public let navigator: any Navigator

    public init(userClient: any UserClient, authClient: any AuthClient, navigator: any Navigator) {
        self.userClient = userClient
        self.authClient = authClient
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

        case .withdrawal:
            let reducer = WithdrawalReducer(
                userClient: dependencies.userClient,
                navigator: dependencies.navigator
            )
            let state = WithdrawalReducer.State(email: dependencies.userClient.cachedEmail())
            return AnyView(WithdrawalView(state: state, reducer: reducer))

        case .editPassword:
            let reducer = EditPasswordReducer(
                userClient: dependencies.userClient,
                navigator: dependencies.navigator
            )
            return AnyView(EditPasswordView(state: EditPasswordReducer.State(), reducer: reducer))

        case .editEmail:
            let reducer = EditEmailReducer(
                userClient: dependencies.userClient,
                authClient: dependencies.authClient,
                navigator: dependencies.navigator
            )
            let state = EditEmailReducer.State(currentEmail: dependencies.userClient.cachedEmail())
            return AnyView(EditEmailView(state: state, reducer: reducer))
        }
    }
}
