import AuthClientTesting
import FeatureTestSupport
import MVICore
import Testing
import UserClientInterface
import UserClientTesting

@testable import SettingFeature

/// 동작 목록 E1~E17 (notes/2026-10-19-R-setting-04-edit-email.md)과 1:1
@Suite("이메일 변경", .timeLimit(.minutes(1)))
struct EditEmailReducerTests {
    private let navigator = RecordingNavigator()
    private let authClient = MockAuthClient()

    private func makeStore(
        _ scenario: MockUserClient.Scenario = .success
    ) -> (Store<EditEmailReducer>, MockUserClient) {
        let client = MockUserClient(scenario)
        let store = Store(
            initialState: EditEmailReducer.State(currentEmail: client.cachedEmail()),
            reducer: EditEmailReducer(
                userClient: client, authClient: authClient, navigator: navigator)
        )
        return (store, client)
    }

    @Test("E2. 저장된 이메일을 그대로 보여 주고 오류·팝업 없이 시작한다")
    func startsWithCachedEmail() {
        let (store, _) = makeStore(.init(email: "ani@pick.com"))

        #expect(store.state.currentEmail == "ani@pick.com")
        #expect(store.state.emailError == nil)
        #expect(store.state.isPasswordMismatch == false)
        #expect(store.state.isCompletionPresented == false)
    }

    @Test("E8·E9. 저장하면 새 이메일·비밀번호를 보내고, 성공하면 완료 팝업을 띄운다")
    func savesAndShowsCompletion() async {
        let (store, client) = makeStore()
        store.send(.newEmailChanged("new@pick.com"))
        store.send(.passwordChanged("pw"))

        await store.send(.saveTapped).finish()

        #expect(client.editedEmails == [.init(newEmail: "new@pick.com", password: "pw")])
        #expect(store.state.isCompletionPresented)
        #expect(navigator.actions.isEmpty)
    }

    @Test(
        "E10. 이메일 오류는 이유에 맞는 문구, 알 수 없는 코드는 \"에러 발생\"",
        arguments: [
            (EditEmailError.emptyEmail, "이메일을 입력해주세요."),
            (.invalidEmailFormat, "올바른 이메일 형식이 아닙니다."),
            (.duplicatedEmail, "이미 존재하는 이메일입니다."),
            (.unexpectedResponse, "에러 발생"),
        ]
    )
    func showsEmailError(error: EditEmailError, message: String) async {
        let (store, _) = makeStore(.init(editEmailResult: .failure(error)))

        await store.send(.saveTapped).finish()

        #expect(store.state.emailError == message)
        #expect(store.state.isCompletionPresented == false)
    }

    @Test("E10·E11. 106은 비밀번호 오류만 켜고, 앞서 뜬 이메일 오류 문구는 그대로 둔다")
    func keepsEmailErrorOnPasswordMismatch() async {
        let (store, _) = makeStore(.init(editEmailResult: .failure(.passwordMismatch)))
        await store.send(.saveFinished(.invalidEmailFormat)).finish()

        await store.send(.saveTapped).finish()

        #expect(store.state.isPasswordMismatch)
        #expect(store.state.emailError == "올바른 이메일 형식이 아닙니다.")
    }

    @Test("E8·E12. 저장을 누르면 비밀번호 오류를 먼저 끄고, 전송 실패면 그대로 둔다")
    func clearsPasswordMismatchOnSave() async {
        let (store, _) = makeStore(.init(editEmailResult: .failure(.transport(.offline))))
        await store.send(.saveFinished(.passwordMismatch)).finish()
        await store.send(.saveFinished(.emptyEmail)).finish()

        await store.send(.saveTapped).finish()

        #expect(store.state.isPasswordMismatch == false)
        #expect(store.state.emailError == "이메일을 입력해주세요.")
    }

    @Test("E14. 완료 팝업의 확인은 누를 때마다 로그아웃한다")
    func logsOutOnConfirm() async {
        let (store, _) = makeStore()

        await store.send(.completionConfirmed).finish()
        await store.send(.completionConfirmed).finish()

        #expect(authClient.logoutCount == 2)
    }

    @Test("E1. 뒤로 버튼은 한 화면 뒤로 간다")
    func goesBack() async {
        let (store, _) = makeStore()

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }
}
