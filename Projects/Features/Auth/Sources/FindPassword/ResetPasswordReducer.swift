import AuthClientInterface
import AuthInterface
import Foundation
import MVICore
import Navigation

/// 비밀번호 찾기 2단계: 새 비밀번호. 동작 목록 RP1~RP6
struct ResetPasswordReducer: Reducer {
    let authClient: any AuthClient
    let navigator: any Navigator

    struct State: Equatable {
        var newPassword = ""
        var confirmation = ""
        /// 계산하지만 화면에 보이지 않는다 (레거시 그대로, RP1)
        var newPasswordGuide = ""
        var confirmationGuide = ""
        var isNewPasswordVisible = false
        var isConfirmationVisible = false
        var isSubmitEnabled = false
    }

    enum Intent: Sendable {
        case newPasswordChanged(String)
        case confirmationChanged(String)
        case newPasswordVisibilityTapped
        case confirmationVisibilityTapped
        case submitTapped
        case resetFinished(Bool)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .newPasswordChanged(let password):
            state.newPassword = password
            state.newPasswordGuide = Self.guide(for: password)
            return .none

        case .confirmationChanged(let confirmation):
            // 버튼은 확인란만 보고 켠다 (RP2)
            state.confirmation = confirmation
            state.isSubmitEnabled = !confirmation.isEmpty
            state.confirmationGuide = Self.guide(for: confirmation)
            return .none

        case .newPasswordVisibilityTapped:
            state.isNewPasswordVisible.toggle()
            return .none

        case .confirmationVisibilityTapped:
            state.isConfirmationVisible.toggle()
            return .none

        case .submitTapped:
            let (password, confirmation) = (state.newPassword, state.confirmation)
            return .run { [authClient] in
                guard
                    let succeeded = try? await authClient.resetPassword(
                        newPassword: password, confirmation: confirmation)
                else {
                    return nil
                }
                return .resetFinished(succeeded)
            }

        case .resetFinished(let succeeded):
            guard succeeded else {
                // 실패 코드는 모두 같은 안내 (RP4)
                state.confirmationGuide = "비밀번호가 일치하지 않습니다."
                return .none
            }
            // 로그인 화면을 스택에 하나 더 쌓는다 (레거시 그대로, RP3)
            return .run { [navigator] in
                await navigator.push(AuthRoute.mainLogin)
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 공백을 자르지 않고 검사한다 (가입 화면과 다름, 레거시 그대로)
    private static func guide(for password: String) -> String {
        let pattern = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        guard !password.isEmpty,
            !NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
        else {
            return ""
        }
        return "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
    }
}
