import Analytics
import AuthClientInterface
import AuthInterface
import ExploreClientInterface
import MetadataClientInterface
import ReviewClientInterface
import Foundation
import Navigation
import SwiftUI

public struct AuthDependencies {
    public let authClient: any AuthClient
    public let exploreClient: any ExploreClient
    public let reviewClient: any ReviewClient
    public let metadataClient: any MetadataClient
    public let navigator: any Navigator
    public let analytics: any AnalyticsTracking
    /// 로그인을 마쳤을 때 (App: 루트를 홈으로 바꾼다 — `NavigationManager.completeLogin`)
    public let onLoginCompleted: @MainActor @Sendable () -> Void
    /// 약관·개인정보 처리방침 외부 링크
    public let openURL: @MainActor @Sendable (URL) -> Void

    public init(
        authClient: any AuthClient,
        exploreClient: any ExploreClient,
        reviewClient: any ReviewClient,
        metadataClient: any MetadataClient,
        navigator: any Navigator,
        analytics: any AnalyticsTracking,
        onLoginCompleted: @escaping @MainActor @Sendable () -> Void = {},
        openURL: @escaping @MainActor @Sendable (URL) -> Void = { _ in }
    ) {
        self.authClient = authClient
        self.exploreClient = exploreClient
        self.reviewClient = reviewClient
        self.metadataClient = metadataClient
        self.navigator = navigator
        self.analytics = analytics
        self.onLoginCompleted = onLoginCompleted
        self.openURL = openURL
    }
}

public struct AuthBuilder: AuthBuilding {
    private let dependencies: AuthDependencies

    public init(dependencies: AuthDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: AuthRoute) -> AnyView {
        switch route {
        case .emailLogin:
            let reducer = EmailLoginReducer(
                authClient: dependencies.authClient,
                navigator: dependencies.navigator,
                analytics: dependencies.analytics,
                onLoginCompleted: dependencies.onLoginCompleted
            )
            return AnyView(EmailLoginView(state: EmailLoginReducer.State(), reducer: reducer))
        case .emailSignup:
            let reducer = EmailSignupReducer(
                authClient: dependencies.authClient,
                navigator: dependencies.navigator,
                analytics: dependencies.analytics,
                openURL: dependencies.openURL
            )
            return AnyView(EmailSignupView(state: EmailSignupReducer.State(), reducer: reducer))
        case .loginProblem:
            return AnyView(LoginProblemView())
        case .findPassword:
            let reducer = FindPasswordReducer(
                authClient: dependencies.authClient,
                navigator: dependencies.navigator
            )
            return AnyView(FindPasswordView(state: FindPasswordReducer.State(), reducer: reducer))
        case .resetPassword:
            let reducer = ResetPasswordReducer(
                authClient: dependencies.authClient,
                navigator: dependencies.navigator
            )
            return AnyView(ResetPasswordView(state: ResetPasswordReducer.State(), reducer: reducer))
        case .preferenceSelection:
            let reducer = PreferenceReducer(
                exploreClient: dependencies.exploreClient,
                reviewClient: dependencies.reviewClient,
                metadataClient: dependencies.metadataClient,
                analytics: dependencies.analytics,
                onLoginCompleted: dependencies.onLoginCompleted
            )
            let state = PreferenceReducer.State(
                genres: dependencies.metadataClient.cachedGenres(),
                seasonYears: dependencies.metadataClient.cachedSeasonYears().map(String.init)
            )
            return AnyView(PreferenceView(state: state, reducer: reducer))
        case .mainLogin:
            // 아직 레거시 화면 — App이 가로챈다
            assertionFailure("레거시 화면 Route가 Auth 빌더로 왔다: \(route)")
            return AnyView(EmptyView())
        }
    }
}

/// 레거시 `LoginProblemView` 그대로 (내용 없는 화면)
struct LoginProblemView: View {
    var body: some View {
        Text("Login Problem View")
    }
}
