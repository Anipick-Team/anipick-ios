import AuthClientInterface
import Foundation
import MVICore
import Navigation
import SettingInterface
import UserClientInterface

/// 설정 메인. 동작 목록: notes/2026-10-19-R-setting-05-setting-main.md
struct SettingReducer: Reducer {
    let userClient: any UserClient
    let authClient: any AuthClient
    let navigator: any Navigator
    let openURL: @MainActor @Sendable (URL) -> Void

    enum Row: String, CaseIterable, Sendable {
        case editNickname = "닉네임 변경"
        case editEmail = "이메일 변경"
        case editPassword = "비밀번호 변경"
        case linkedSNS = "연동 SNS"
        case appVersion = "앱 버전"
        case inquiry = "문의하기"
        case termsOfService = "서비스 이용약관"
        case privacyPolicy = "개인정보 처리방침"
        case notice = "공지사항"
        case logout = "로그아웃"
        case deleteAccount = "회원 탈퇴"
    }

    struct State: Equatable {
        /// 처음 그릴 때는 빈 값, 나타날 때마다 다시 읽는다 (M2)
        var nickname = ""
        var email = ""
        /// `KAKAO`·`GOOGLE`·`APPLE`, 이메일 가입이면 `""`
        var snsAccount: String
        var appVersion: String?
        var isLogoutPopupPresented = false

        var isSNSAccount: Bool {
            return !snsAccount.isEmpty
        }

        /// M3
        var snsName: String {
            switch snsAccount {
            case "KAKAO":
                return "카카오톡"
            case "GOOGLE":
                return "구글"
            case "APPLE":
                return "애플"
            default:
                return ""
            }
        }
    }

    enum Intent: Sendable {
        case appeared
        case rowTapped(Row)
        case logoutCancelled
        case logoutConfirmed
        case backTapped
    }

    static let inquiryURL = URL(string: "https://forms.gle/SJ7mbQfyfoe2HDLd7")!
    static let termsURL = URL(string: "https://anipick.p-e.kr/terms.html")!
    static let privacyURL = URL(string: "https://anipick.p-e.kr/privacy.html")!
    static let noticeURL = URL(
        string:
            "https://spiral-cowl-f89.notion.site/227b3eed42088098a351ff047659bdcb?source=copy_link"
    )!

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            state.nickname = userClient.cachedNickname()
            state.email = userClient.cachedEmail()
            return .none

        case .rowTapped(let row):
            return action(for: row, state: &state)

        case .logoutCancelled:
            state.isLogoutPopupPresented = false
            return .none

        case .logoutConfirmed:
            // 팝업은 Session이 루트를 바꿀 때까지 둔다 (M15)
            return .run { [authClient] in
                await authClient.logoutImmediately()
                return nil
            }

        case .backTapped:
            return push(nil)
        }
    }

    private func action(for row: Row, state: inout State) -> Effect<Intent> {
        switch row {
        case .editNickname:
            return push(.editNickname)
        case .editEmail:
            return state.isSNSAccount ? .none : push(.editEmail)
        case .editPassword:
            return state.isSNSAccount ? .none : push(.editPassword)
        case .linkedSNS, .appVersion:
            return .none
        case .inquiry:
            return open(Self.inquiryURL)
        case .termsOfService:
            return open(Self.termsURL)
        case .privacyPolicy:
            return open(Self.privacyURL)
        case .notice:
            return open(Self.noticeURL)
        case .logout:
            state.isLogoutPopupPresented = true
            return .none
        case .deleteAccount:
            return push(.withdrawal)
        }
    }

    /// nil이면 뒤로
    private func push(_ route: SettingRoute?) -> Effect<Intent> {
        return .run { [navigator] in
            if let route {
                await navigator.push(route)
            } else {
                await navigator.pop()
            }
            return nil
        }
    }

    private func open(_ url: URL) -> Effect<Intent> {
        return .run { [openURL] in
            await openURL(url)
            return nil
        }
    }
}
