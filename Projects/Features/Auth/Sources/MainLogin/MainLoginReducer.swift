import Analytics
import AuthClientInterface
import AuthInterface
import Foundation
import MVICore
import Navigation

/// 메인 로그인(카카오·구글·애플·이메일). 동작 목록: notes/2026-10-30-R-auth-05-main-login.md (ML1~ML12)
struct MainLoginReducer: Reducer {
    static let problemFormURL = URL(string: "https://forms.gle/SJ7mbQfyfoe2HDLd7")!

    let authClient: any AuthClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    let onLoginCompleted: @MainActor @Sendable () -> Void
    let openURL: @MainActor @Sendable (URL) -> Void

    /// 애플 로그인 결과. `ASAuthorization`은 Sendable이 아니라 View가 여기까지 줄여 보낸다
    enum AppleOutcome: Equatable, Sendable {
        case token(String)
        case credentialCastFailed
        case emptyIdentityToken
        case failed(NSError)
    }

    struct State: Equatable {
        var isWithdrawnPopupPresented = false
        var existingAccount: ExistingAccount?
    }

    enum Intent: Sendable {
        case kakaoTapped
        case googleTapped
        case appleCompleted(AppleOutcome)
        case socialLoginFinished(SocialProvider, SocialLoginResult)
        case emailSignupTapped
        case emailLoginTapped
        case problemTapped
        case withdrawnPopupClosed
        case existingAccountClosed
        case existingAccountConfirmed
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .kakaoTapped:
            return .run { [authClient, analytics] in
                do throws(SocialSignInFailure) {
                    let token = try await authClient.kakaoAccessToken()
                    return await login(.kakao, code: token)
                } catch {
                    record(error, provider: .kakao, context: "login_kakao", analytics)
                    return nil
                }
            }

        case .googleTapped:
            return .run { [authClient, analytics] in
                do throws(SocialSignInFailure) {
                    let token = try await authClient.googleIDToken()
                    return await login(.google, code: token)
                } catch {
                    record(error, provider: .google, context: "login_google_signIn", analytics)
                    return nil
                }
            }

        case .appleCompleted(let outcome):
            return .run { [analytics] in
                switch outcome {
                case .token(let token):
                    return await login(.apple, code: token)
                case .credentialCastFailed:
                    analytics.logLoginIssue(provider: "apple", reason: "credential cast failed")
                case .emptyIdentityToken:
                    analytics.logLoginIssue(provider: "apple", reason: "empty identityToken")
                case .failed(let error):
                    analytics.logError(error, context: "login_apple_authorization")
                }
                return nil
            }

        case .socialLoginFinished(let provider, let result):
            return handle(result, provider: provider, &state)

        case .emailSignupTapped:
            return push(.emailSignup)

        case .emailLoginTapped:
            return push(.emailLogin)

        case .problemTapped:
            return .run { [openURL] in
                await openURL(Self.problemFormURL)
                return nil
            }

        case .withdrawnPopupClosed:
            state.isWithdrawnPopupPresented.toggle()
            return .none

        case .existingAccountClosed:
            state.existingAccount = nil
            return .none

        case .existingAccountConfirmed:
            // 이메일로 가입된 계정이면 이메일 로그인으로 간다. 나머지는 닫기만 한다 (ML9)
            let account = state.existingAccount
            state.existingAccount = nil
            return account == .email ? push(.emailLogin) : .none
        }
    }

    /// 토큰을 서버에 보낸다. 전송에 실패하면 `login_social_{provider}` 오류로 남긴다
    private func login(_ provider: SocialProvider, code: String) async -> Intent? {
        do {
            return .socialLoginFinished(
                provider, try await authClient.socialLogin(provider, code: code))
        } catch {
            analytics.logError(error, context: "login_social_\(provider.rawValue)")
            return nil
        }
    }

    private nonisolated func record(
        _ failure: SocialSignInFailure,
        provider: SocialProvider,
        context: String,
        _ analytics: any AnalyticsTracking
    ) {
        switch failure {
        case .issue(let reason):
            analytics.logLoginIssue(provider: provider.rawValue, reason: reason)
        case .sdk(let error):
            analytics.logError(error, context: context)
        }
    }

    private func handle(_ result: SocialLoginResult, provider: SocialProvider, _ state: inout State)
        -> Effect<Intent>
    {
        switch result {
        case .success(let user):
            return .run { [analytics, navigator, onLoginCompleted] in
                if !user.hasAccessToken {
                    analytics.logLoginIssue(
                        provider: provider.rawValue, reason: "200 but empty accessToken")
                }
                analytics.setUser(id: user.userId.map(String.init), loginMethod: provider.rawValue)
                analytics.log(.login(method: provider.rawValue))
                // 취향 평가를 마친 사용자(값이 없으면 마친 것으로 본다)는 홈, 아니면 취향 선택 (ML6)
                if user.reviewCompleted ?? true {
                    await onLoginCompleted()
                } else {
                    await navigator.push(AuthRoute.preferenceSelection)
                }
                return nil
            }
        case .withdrawn:
            state.isWithdrawnPopupPresented.toggle()
            return .none
        case .existingAccount(let account):
            state.existingAccount = account
            return .none
        case .unexpected(let code):
            return .run { [analytics] in
                analytics.logLoginIssue(
                    provider: provider.rawValue, reason: "unhandled response code: \(code)")
                return nil
            }
        }
    }

    private func push(_ route: AuthRoute) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
