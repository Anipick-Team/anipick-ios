import AuthClientInterface
import MVICore
import Navigation
import UserClientInterface

/// 이메일 변경. 동작 목록: notes/2026-10-19-R-setting-04-edit-email.md
struct EditEmailReducer: Reducer {
    let userClient: any UserClient
    let authClient: any AuthClient
    let navigator: any Navigator

    struct State: Equatable {
        var currentEmail: String
        var newEmail = ""
        var password = ""
        /// 한 번 뜨면 지우지 않는다 (E10)
        var emailError: String?
        var isPasswordMismatch = false
        var isCompletionPresented = false
    }

    enum Intent: Sendable {
        case newEmailChanged(String)
        case passwordChanged(String)
        case saveTapped
        /// nil이면 성공
        case saveFinished(EditEmailError?)
        case completionConfirmed
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .newEmailChanged(let email):
            state.newEmail = email
            return .none

        case .passwordChanged(let password):
            state.password = password
            return .none

        case .saveTapped:
            state.isPasswordMismatch = false
            let (email, password) = (state.newEmail, state.password)
            return .run { [userClient] in
                do throws(EditEmailError) {
                    try await userClient.editEmail(newEmail: email, password: password)
                    return .saveFinished(nil)
                } catch {
                    return .saveFinished(error)
                }
            }

        case .saveFinished(let error):
            switch error {
            case nil:
                state.isCompletionPresented = true
            case .emptyEmail:
                state.emailError = "이메일을 입력해주세요."
            case .invalidEmailFormat:
                state.emailError = "올바른 이메일 형식이 아닙니다."
            case .duplicatedEmail:
                state.emailError = "이미 존재하는 이메일입니다."
            case .unexpectedResponse:
                state.emailError = "에러 발생"
            case .passwordMismatch:
                // 이메일 오류 문구는 그대로 둔다 (E11)
                state.isPasswordMismatch = true
            case .transport:
                break
            }
            return .none

        case .completionConfirmed:
            // 누를 때마다 보낸다. 로그인 화면 전환은 Session이 한다 (E14)
            return .run { [authClient] in
                await authClient.logout()
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }
}
