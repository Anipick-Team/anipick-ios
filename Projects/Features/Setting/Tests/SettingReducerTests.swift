import AuthClientTesting
import Foundation
import MVICore
import SettingInterface
import Testing
import UserClientTesting

@testable import SettingFeature

/// 외부 링크 열기를 기록한다
@MainActor
final class RecordingURLOpener {
    private(set) var urls: [URL] = []

    func open(_ url: URL) {
        urls.append(url)
    }
}

/// 동작 목록 M1~M17 (notes/2026-10-19-R-setting-05-setting-main.md)과 1:1
@Suite("설정 메인", .timeLimit(.minutes(1)))
struct SettingReducerTests {
    private let navigator = RecordingNavigator()
    private let authClient = MockAuthClient()
    private let opener = RecordingURLOpener()

    private func makeStore(_ scenario: MockUserClient.Scenario = .success) -> Store<SettingReducer>
    {
        let client = MockUserClient(scenario)
        let reducer = SettingReducer(
            userClient: client,
            authClient: authClient,
            navigator: navigator,
            openURL: { [opener] in opener.open($0) }
        )
        return Store(
            initialState: SettingReducer.State(
                snsAccount: client.cachedSNSAccount(), appVersion: "1.2.0"),
            reducer: reducer
        )
    }

    @Test("M2. 처음에는 닉네임·이메일이 비어 있고, 나타나면 저장된 값을 읽는다")
    func loadsProfileOnAppear() {
        let store = makeStore(.init(nickname: "애니픽", email: "ani@pick.com"))
        #expect(store.state.nickname == "")
        #expect(store.state.email == "")

        store.send(.appeared)

        #expect(store.state.nickname == "애니픽")
        #expect(store.state.email == "ani@pick.com")
    }

    @Test(
        "M3. 저장된 SNS 값을 이름으로 바꾼다",
        arguments: [("KAKAO", "카카오톡"), ("GOOGLE", "구글"), ("APPLE", "애플"), ("NAVER", ""), ("", "")]
    )
    func namesSNS(account: String, name: String) {
        let store = makeStore(.init(snsAccount: account))

        #expect(store.state.snsName == name)
        #expect(store.state.isSNSAccount == !account.isEmpty)
    }

    @Test(
        "M8·M9·M12. 행을 누르면 해당 화면으로 간다 (이메일 가입 계정)",
        arguments: [
            (SettingReducer.Row.editNickname, SettingRoute.editNickname), (.editEmail, .editEmail),
            (.editPassword, .editPassword), (.deleteAccount, .withdrawal),
        ]
    )
    func pushesRoute(row: SettingReducer.Row, route: SettingRoute) async {
        let store = makeStore()

        await store.send(.rowTapped(row)).finish()

        #expect(navigator.actions == [.push(AnyHashable(route))])
    }

    @Test("M9. SNS 계정은 이메일·비밀번호 변경으로 가지 않는다 (닉네임은 간다)")
    func blocksEmailAndPasswordForSNS() async {
        let store = makeStore(.init(snsAccount: "KAKAO"))

        await store.send(.rowTapped(.editEmail)).finish()
        await store.send(.rowTapped(.editPassword)).finish()
        await store.send(.rowTapped(.editNickname)).finish()

        #expect(navigator.actions == [.push(AnyHashable(SettingRoute.editNickname))])
    }

    @Test("M10. 연동 SNS·앱 버전은 아무것도 하지 않는다")
    func ignoresInfoRows() async {
        let store = makeStore()

        await store.send(.rowTapped(.linkedSNS)).finish()
        await store.send(.rowTapped(.appVersion)).finish()

        #expect(navigator.actions.isEmpty)
        #expect(opener.urls.isEmpty)
        #expect(store.state.isLogoutPopupPresented == false)
    }

    @Test(
        "M11. 문의·약관·개인정보·공지사항은 외부 링크를 연다",
        arguments: [
            (SettingReducer.Row.inquiry, "https://forms.gle/SJ7mbQfyfoe2HDLd7"),
            (.termsOfService, "https://anipick.p-e.kr/terms.html"),
            (.privacyPolicy, "https://anipick.p-e.kr/privacy.html"),
            (
                .notice,
                "https://spiral-cowl-f89.notion.site/227b3eed42088098a351ff047659bdcb?source=copy_link"
            ),
        ]
    )
    func opensExternalLink(row: SettingReducer.Row, url: String) async {
        let store = makeStore()

        await store.send(.rowTapped(row)).finish()

        #expect(opener.urls == [URL(string: url)])
        #expect(navigator.actions.isEmpty)
    }

    @Test("M13·M14. 로그아웃은 팝업을 띄우고, 취소하면 닫는다")
    func showsAndCancelsLogoutPopup() {
        let store = makeStore()

        store.send(.rowTapped(.logout))
        #expect(store.state.isLogoutPopupPresented)

        store.send(.logoutCancelled)
        #expect(store.state.isLogoutPopupPresented == false)
        #expect(authClient.immediateLogoutCount == 0)
    }

    @Test("M15. 팝업의 로그아웃은 기다리지 않는 로그아웃을 하고, 팝업은 그대로 둔다")
    func logsOutImmediately() async {
        let store = makeStore()
        store.send(.rowTapped(.logout))

        await store.send(.logoutConfirmed).finish()

        #expect(authClient.immediateLogoutCount == 1)
        #expect(authClient.logoutCount == 0)
        #expect(store.state.isLogoutPopupPresented)
    }

    @Test("M1. 뒤로 버튼은 한 화면 뒤로 간다")
    func goesBack() async {
        let store = makeStore()

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }
}
