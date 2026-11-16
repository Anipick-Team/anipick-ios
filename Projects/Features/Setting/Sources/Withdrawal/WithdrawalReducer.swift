import MVICore
import Navigation
import UserClientInterface

/// 회원 탈퇴. 동작 목록: notes/2026-10-19-R-setting-02-withdrawal.md
struct WithdrawalReducer: Reducer {
    let userClient: any UserClient
    let navigator: any Navigator

    struct State: Equatable {
        var email: String

        /// 자동 링크 방지로 `@` 뒤에 U+200B를 넣는다 (W2)
        var displayedEmail: String {
            return email.replacingOccurrences(of: "@", with: "@\u{200B}")
        }
    }

    enum Intent: Sendable {
        case withdrawTapped
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .withdrawTapped:
            // 성공하면 Session이 로그인 화면으로 바꾼다 (W6). 실패는 무시한다 (W7)
            return .run { [userClient] in
                try? await userClient.withdraw()
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
