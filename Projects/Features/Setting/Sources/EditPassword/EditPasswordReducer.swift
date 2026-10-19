import Foundation
import MVICore
import Navigation
import UserClientInterface

/// 비밀번호 변경. 동작 목록: notes/2026-10-19-R-setting-03-edit-password.md
struct EditPasswordReducer: Reducer {
    let userClient: any UserClient
    let navigator: any Navigator

    struct State: Equatable {
        var currentPassword = ""
        var newPassword = ""
        var confirmation = ""
        var isNewPasswordValid = false
        /// 한 번 켜지면 끄지 않는다 (P6)
        var isConfirmationMatched = false
        var currentPasswordError: String?
        var newPasswordError: String?
        var confirmationError: String?
    }

    enum Intent: Sendable {
        case currentPasswordChanged(String)
        case newPasswordChanged(String)
        case confirmationChanged(String)
        case saveTapped
        /// nil이면 성공
        case saveFinished(EditPasswordError?)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .currentPasswordChanged(let password):
            state.currentPassword = password
            return .none

        case .newPasswordChanged(let password):
            state.newPassword = password
            state.isNewPasswordValid = Self.isValid(password)
            // 유효해져도 지우지 않는다 — 저장 응답 때만 지운다 (P5)
            if !state.isNewPasswordValid {
                state.newPasswordError = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
            }
            return .none

        case .confirmationChanged(let confirmation):
            state.confirmation = confirmation
            if state.newPassword == confirmation {
                state.isConfirmationMatched = true
            }
            return .none

        case .saveTapped:
            let (current, new, confirmation) = (
                state.currentPassword, state.newPassword, state.confirmation
            )
            return .run { [userClient] in
                do throws(EditPasswordError) {
                    try await userClient.editPassword(
                        current: current, new: new, confirmation: confirmation)
                    return .saveFinished(nil)
                } catch {
                    return .saveFinished(error)
                }
            }

        case .saveFinished(let error):
            // 결과와 무관하게 먼저 모두 지운다 (P8·P9)
            state.currentPasswordError = nil
            state.newPasswordError = nil
            state.confirmationError = nil
            switch error {
            case nil:
                return .run { [navigator] in
                    await navigator.pop()
                    return nil
                }
            case .currentPasswordMismatch:
                state.currentPasswordError = "현재 비밀번호가 일치하지 않습니다. 다시 입력해주세요."
            case .confirmationMismatch:
                state.confirmationError = "비밀번호가 일치하지 않습니다."
            case .unexpectedResponse, .transport:
                break
            }
            return .none

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 10자 이상 + 영문·숫자·특수문자 중 2종 이상 (레거시 `EditPasswordViewModel.swift:55-67`)
    static func isValid(_ password: String) -> Bool {
        let hasLetter = password.range(of: "[a-zA-Z]", options: .regularExpression) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let kinds = [hasLetter, hasNumber, hasSpecial].filter { $0 }.count
        return password.count >= 10 && kinds >= 2
    }
}
