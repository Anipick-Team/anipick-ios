import AuthClientInterface
import Foundation
import Navigation
import SettingInterface
import SwiftUI
import UserClientInterface

public struct SettingDependencies {
    public let userClient: any UserClient
    public let authClient: any AuthClient
    public let navigator: any Navigator
    /// 문의하기·약관 등 외부 링크
    public let openURL: @MainActor @Sendable (URL) -> Void
    /// "앱 버전" 행에 보일 값 (App: `CFBundleShortVersionString`)
    public let appVersion: String?

    public init(
        userClient: any UserClient,
        authClient: any AuthClient,
        navigator: any Navigator,
        openURL: @escaping @MainActor @Sendable (URL) -> Void = { _ in },
        appVersion: String? = nil
    ) {
        self.userClient = userClient
        self.authClient = authClient
        self.navigator = navigator
        self.openURL = openURL
        self.appVersion = appVersion
    }
}

public struct SettingBuilder: SettingBuilding {
    private let dependencies: SettingDependencies

    public init(dependencies: SettingDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: SettingRoute) -> AnyView {
        switch route {
        case .main:
            let reducer = SettingReducer(
                userClient: dependencies.userClient,
                authClient: dependencies.authClient,
                navigator: dependencies.navigator,
                openURL: dependencies.openURL
            )
            let state = SettingReducer.State(
                snsAccount: dependencies.userClient.cachedSNSAccount(),
                appVersion: dependencies.appVersion
            )
            return AnyView(SettingView(state: state, reducer: reducer))

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
