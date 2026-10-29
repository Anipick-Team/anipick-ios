import Analytics
import AuthClientInterface
import AuthInterface
import Foundation
import MVICore
import Navigation

/// 이메일 회원가입. 동작 목록: notes/2026-10-29-R-auth-02-signup.md (SU1~SU10)
struct EmailSignupReducer: Reducer {
    static let termsURL = URL(string: "https://anipick.p-e.kr/terms.html")!
    static let privacyURL = URL(string: "https://anipick.p-e.kr/privacy.html")!

    let authClient: any AuthClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    let openURL: @MainActor @Sendable (URL) -> Void

    struct State: Equatable {
        var email = ""
        var password = ""
        var emailGuide = ""
        var passwordGuide = ""
        var isPasswordVisible = false
        var agreesAll = false
        var agreesOverFourteen = false
        var agreesTerms = false
        var agreesPrivacy = false
        var isSignupEnabled = false

        /// 비밀번호 오른쪽 체크 (앞뒤 공백을 빼고 검사, SU3)
        var isPasswordValid: Bool {
            return EmailSignupReducer.isValidPassword(password)
        }
    }

    enum Intent: Sendable {
        case emailChanged(String)
        case passwordChanged(String)
        case passwordVisibilityTapped
        case agreeAllTapped
        case overFourteenTapped
        case termsTapped
        case privacyTapped
        case signupTapped
        case signupFinished(EmailSignupResult)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .emailChanged(let email):
            state.email = email
            state.emailGuide = EmailLoginReducer.emailGuide(for: email)
            updateEnabled(&state)
            return .none

        case .passwordChanged(let password):
            state.password = password
            updateEnabled(&state)
            if password.isEmpty || Self.isValidPassword(password) {
                state.passwordGuide = ""
            } else {
                state.passwordGuide = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
            }
            return .none

        case .passwordVisibilityTapped:
            state.isPasswordVisible.toggle()
            return .none

        case .agreeAllTapped:
            let agrees = !state.agreesAll
            state.agreesAll = agrees
            state.agreesOverFourteen = agrees
            state.agreesTerms = agrees
            state.agreesPrivacy = agrees
            updateEnabled(&state)
            return .none

        case .overFourteenTapped:
            state.agreesOverFourteen.toggle()
            updateAgreeAll(&state)
            return .none

        case .termsTapped:
            // 동의를 바꾸고 약관을 연다 (SU5)
            state.agreesTerms.toggle()
            updateAgreeAll(&state)
            return open(Self.termsURL)

        case .privacyTapped:
            state.agreesPrivacy.toggle()
            updateAgreeAll(&state)
            return open(Self.privacyURL)

        case .signupTapped:
            let (email, password, agrees) = (state.email, state.password, state.agreesAll)
            return .run { [authClient] in
                guard
                    let result = try? await authClient.signupWithEmail(
                        email: email, password: password, agreedToTerms: agrees)
                else {
                    return nil
                }
                return .signupFinished(result)
            }

        case .signupFinished(let result):
            switch result {
            case .success:
                // 가입 응답에는 userId가 없어 로그인 방식만 붙인다 (SU7)
                return .run { [analytics, navigator] in
                    analytics.setUser(id: nil, loginMethod: "email")
                    analytics.log(.signUp)
                    await navigator.push(AuthRoute.preferenceSelection)
                    return nil
                }
            case .duplicatedEmail:
                state.emailGuide = "이미 가입한 이메일입니다."
                return .none
            case .unexpected:
                return .none
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 이메일·비밀번호가 있고 모두 동의했을 때 (SU6)
    private func updateEnabled(_ state: inout State) {
        state.isSignupEnabled = !state.email.isEmpty && !state.password.isEmpty && state.agreesAll
    }

    private func updateAgreeAll(_ state: inout State) {
        state.agreesAll = state.agreesOverFourteen && state.agreesTerms && state.agreesPrivacy
        updateEnabled(&state)
    }

    private func open(_ url: URL) -> Effect<Intent> {
        return .run { [openURL] in
            await openURL(url)
            return nil
        }
    }

    static func isValidPassword(_ password: String) -> Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
    }
}
