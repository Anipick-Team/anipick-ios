import Analytics
import AuthClientInterface
import AuthInterface
import Foundation
import MVICore
import Navigation

/// 이메일 로그인. 동작 목록: notes/2026-10-29-R-auth-01-email-login.md (EL1~EL12)
struct EmailLoginReducer: Reducer {
    let authClient: any AuthClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    let onLoginCompleted: @MainActor @Sendable () -> Void

    struct State: Equatable {
        var email = ""
        var password = ""
        var emailGuide = ""
        var passwordGuide = ""
        var commonGuide = ""
        /// 비밀번호를 바꿀 때만 다시 계산한다 — 레거시는 이메일 입력에서 버튼 상태를 갱신하지 않는다 (EL3)
        var isLoginEnabled = false
        var isPasswordVisible = false
        var isWithdrawnPopupPresented = false
    }

    enum Intent: Sendable {
        case emailChanged(String)
        case passwordChanged(String)
        case passwordVisibilityTapped
        case loginTapped
        case loginFinished(EmailLoginResult)
        case signupTapped
        case findPasswordTapped
        case backTapped
        case withdrawnPopupClosed
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .emailChanged(let email):
            state.email = email
            state.emailGuide = Self.emailGuide(for: email)
            return .none

        case .passwordChanged(let password):
            state.password = password
            state.passwordGuide = Self.passwordGuide(for: password)
            state.isLoginEnabled = !state.email.isEmpty && !password.isEmpty
            return .none

        case .passwordVisibilityTapped:
            state.isPasswordVisible.toggle()
            return .none

        case .loginTapped:
            // 버튼은 비활성이어도 눌린다 — 색만 바뀐다 (레거시 FullWidthButton, EL5)
            let (email, password) = (state.email, state.password)
            return .run { [authClient, analytics] in
                do {
                    return .loginFinished(
                        try await authClient.loginWithEmail(email: email, password: password))
                } catch {
                    analytics.logError(error, context: "login_email")
                    return nil
                }
            }

        case .loginFinished(let result):
            state.emailGuide = ""
            state.commonGuide = ""
            state.passwordGuide = ""
            return handle(result, &state)

        case .signupTapped:
            return push(AuthRoute.emailSignup)

        case .findPasswordTapped:
            return push(AuthRoute.findPassword)

        case .backTapped:
            return pop()

        case .withdrawnPopupClosed:
            state.isWithdrawnPopupPresented.toggle()
            return pop()
        }
    }

    /// 레거시 응답 코드 분기 (EL6~EL10)
    private func handle(_ result: EmailLoginResult, _ state: inout State) -> Effect<Intent> {
        switch result {
        case .success(let user):
            return .run { [analytics, onLoginCompleted] in
                if !user.hasAccessToken {
                    analytics.logLoginIssue(provider: "email", reason: "200 but empty accessToken")
                }
                analytics.setUser(id: user.userId.map(String.init), loginMethod: "email")
                analytics.log(.login(method: "email"))
                await onLoginCompleted()
                return nil
            }
        case .missingResult:
            return issue("200 but result nil")
        case .invalidPasswordFormat:
            state.passwordGuide = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요."
        case .wrongCredentials:
            state.commonGuide = "이메일이나 비밀번호를 확인해주세요."
        case .emptyPassword:
            state.passwordGuide = "비밀번호를 입력해주세요."
        case .accountNotFound:
            state.emailGuide = "가입된 계정이 없습니다. 이메일을 다시 확인해주세요."
        case .withdrawn:
            state.isWithdrawnPopupPresented.toggle()
        case .emptyEmail:
            state.emailGuide = "이메일 주소를 입력해 주세요."
        case .unexpected(let code):
            return issue("unhandled response code: \(code)")
        }
        return .none
    }

    private func issue(_ reason: String) -> Effect<Intent> {
        return .run { [analytics] in
            analytics.logLoginIssue(provider: "email", reason: reason)
            return nil
        }
    }

    static func emailGuide(for email: String) -> String {
        if email.isEmpty {
            return "이메일을 입력해주세요."
        }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed) else {
            return "올바른 이메일 형식이 아닙니다."
        }
        return ""
    }

    /// 영문·숫자·특수문자를 하나씩 포함한 8~16자 (레거시 정규식)
    static func passwordGuide(for password: String) -> String {
        if password.isEmpty {
            return "비밀번호를 입력해주세요."
        }
        let pattern = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        guard NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password) else {
            return "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
        }
        return ""
    }

    private func push(_ route: AuthRoute) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }

    private func pop() -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.pop()
            return nil
        }
    }
}
