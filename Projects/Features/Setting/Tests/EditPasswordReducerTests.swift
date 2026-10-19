import MVICore
import Testing
import UserClientInterface
import UserClientTesting

@testable import SettingFeature

/// 동작 목록 P1~P12 (notes/2026-10-19-R-setting-03-edit-password.md)과 1:1
@Suite("비밀번호 변경", .timeLimit(.minutes(1)))
struct EditPasswordReducerTests {
    private let navigator = RecordingNavigator()
    private let invalidMessage = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."

    private func makeStore(_ scenario: MockUserClient.Scenario = .success) -> (
        Store<EditPasswordReducer>, MockUserClient
    ) {
        let client = MockUserClient(scenario)
        let store = Store(
            initialState: EditPasswordReducer.State(),
            reducer: EditPasswordReducer(userClient: client, navigator: navigator)
        )
        return (store, client)
    }

    @Test(
        "P4. 10자 이상 + 영문·숫자·특수문자 중 2종 이상이면 유효",
        arguments: [
            ("abcdefghi1", true), ("abcdefgh!!", true), ("1234567!!!", true), ("abcdefghij", false),
            ("abcde1!", false), ("1234567890", false), ("", false),
        ]
    )
    func validatesNewPassword(password: String, isValid: Bool) {
        #expect(EditPasswordReducer.isValid(password) == isValid)
    }

    @Test("P5. 무효이면 오류 문구를 띄우고, 이후 유효해져도 지우지 않는다")
    func keepsInvalidMessage() {
        let (store, _) = makeStore()

        store.send(.newPasswordChanged("short"))
        #expect(store.state.isNewPasswordValid == false)
        #expect(store.state.newPasswordError == invalidMessage)

        store.send(.newPasswordChanged("abcdefghi1"))
        #expect(store.state.isNewPasswordValid)
        #expect(store.state.newPasswordError == invalidMessage)
    }

    @Test("P6. 확인란이 새 비밀번호와 같으면 일치 표시, 한 번 켜지면 끄지 않는다")
    func matchesConfirmationSticky() {
        let (store, _) = makeStore()
        store.send(.newPasswordChanged("abcdefghi1"))

        store.send(.confirmationChanged("abc"))
        #expect(store.state.isConfirmationMatched == false)
        store.send(.confirmationChanged("abcdefghi1"))
        #expect(store.state.isConfirmationMatched)
        store.send(.confirmationChanged("abcdefghi"))
        #expect(store.state.isConfirmationMatched)
        // 새 비밀번호를 바꿀 때는 비교하지 않는다
        store.send(.newPasswordChanged("zzzzzzzzz1"))
        #expect(store.state.isConfirmationMatched)
    }

    @Test("P7·P8. 저장하면 세 값을 보내고, 성공하면 오류를 모두 지우고 뒤로 간다")
    func savesAndGoesBack() async {
        let (store, client) = makeStore()
        store.send(.currentPasswordChanged("old"))
        store.send(.newPasswordChanged("short"))
        store.send(.confirmationChanged("short"))

        await store.send(.saveTapped).finish()

        #expect(
            client.editedPasswords == [.init(current: "old", new: "short", confirmation: "short")])
        #expect(store.state.newPasswordError == nil)
        #expect(await waitUntil { navigator.actions == [.pop] })
    }

    @Test("P8. 107이면 현재 비밀번호 오류만 남긴다")
    func showsCurrentPasswordMismatch() async {
        let (store, _) = makeStore(.init(editPasswordResult: .failure(.currentPasswordMismatch)))
        store.send(.newPasswordChanged("short"))

        await store.send(.saveTapped).finish()

        #expect(store.state.currentPasswordError == "현재 비밀번호가 일치하지 않습니다. 다시 입력해주세요.")
        #expect(store.state.newPasswordError == nil)
        #expect(store.state.confirmationError == nil)
        #expect(navigator.actions.isEmpty)
    }

    @Test("P8. 108이면 확인 오류만 남긴다")
    func showsConfirmationMismatch() async {
        let (store, _) = makeStore(.init(editPasswordResult: .failure(.confirmationMismatch)))
        store.send(.newPasswordChanged("short"))

        await store.send(.saveTapped).finish()

        #expect(store.state.confirmationError == "비밀번호가 일치하지 않습니다.")
        #expect(store.state.newPasswordError == nil)
        #expect(navigator.actions.isEmpty)
    }

    @Test(
        "P8·P9. 그 밖의 코드·전송 실패는 오류 문구를 모두 지우기만 한다",
        arguments: [EditPasswordError.unexpectedResponse, .transport(.offline)]
    )
    func clearsErrorsOnOtherFailures(error: EditPasswordError) async {
        let (store, _) = makeStore(.init(editPasswordResult: .failure(error)))
        store.send(.newPasswordChanged("short"))
        await store.send(.saveFinished(.currentPasswordMismatch)).finish()
        store.send(.newPasswordChanged("short"))

        await store.send(.saveTapped).finish()

        #expect(store.state.currentPasswordError == nil)
        #expect(store.state.newPasswordError == nil)
        #expect(store.state.confirmationError == nil)
        #expect(navigator.actions.isEmpty)
    }

    @Test("P1. 뒤로 버튼은 한 화면 뒤로 간다")
    func goesBack() async {
        let (store, _) = makeStore()

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }
}
