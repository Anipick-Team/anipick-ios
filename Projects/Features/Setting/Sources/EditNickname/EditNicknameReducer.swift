import MVICore
import Navigation
import UserClientInterface

/// 닉네임 변경. 동작 목록: notes/2026-10-19-R-setting-01-edit-nickname.md
struct EditNicknameReducer: Reducer {
    let userClient: any UserClient
    let navigator: any Navigator

    struct State: Equatable {
        var currentNickname: String
        var newNickname = ""
        /// nil이면 숨김 (B12)
        var errorMessage: String?
    }

    enum Intent: Sendable {
        case newNicknameChanged(String)
        case saveTapped
        case saveSucceeded
        case saveFailed(EditNicknameError)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .newNicknameChanged(let nickname):
            state.newNickname = nickname
            return .none

        case .saveTapped:
            // 연속으로 눌러도 레거시처럼 요청마다 보낸다 (id 없음)
            let nickname = state.newNickname
            return .run { [userClient] in
                do throws(EditNicknameError) {
                    try await userClient.editNickname(nickname)
                    return .saveSucceeded
                } catch {
                    return .saveFailed(error)
                }
            }

        case .saveSucceeded:
            state.errorMessage = nil
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }

        case .saveFailed(let error):
            switch error {
            case .duplicated:
                state.errorMessage = "이미 사용 중인 닉네임입니다."
            case .invalidFormat:
                state.errorMessage = "1~20자의 한글, 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
            case .empty:
                state.errorMessage = "닉네임을 입력해 주세요."
            case .unexpectedResponse, .transport:
                // 레거시: 그 밖의 코드·전송 실패는 화면을 바꾸지 않는다 (B11)
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
}
