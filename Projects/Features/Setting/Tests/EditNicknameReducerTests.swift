import FeatureTestSupport
import MVICore
import Navigation
import Testing
import UserClientInterface
import UserClientTesting

@testable import SettingFeature

/// 동작 목록 B1~B13 (notes/2026-10-19-R-setting-01-edit-nickname.md)과 1:1
@Suite("닉네임 변경", .timeLimit(.minutes(1)))
struct EditNicknameReducerTests {
    private let navigator = RecordingNavigator()

    private func makeStore(_ scenario: MockUserClient.Scenario) -> (
        Store<EditNicknameReducer>, MockUserClient
    ) {
        let client = MockUserClient(scenario)
        let reducer = EditNicknameReducer(userClient: client, navigator: navigator)
        let store = Store(
            initialState: EditNicknameReducer.State(currentNickname: client.cachedNickname()),
            reducer: reducer
        )
        return (store, client)
    }

    @Test("B3. 저장된 닉네임으로 시작하고 오류 문구는 없다")
    func startsWithCachedNickname() {
        let (store, _) = makeStore(.init(nickname: "애니픽"))

        #expect(store.state.currentNickname == "애니픽")
        #expect(store.state.newNickname == "")
        #expect(store.state.errorMessage == nil)
    }

    @Test("B2. 뒤로 버튼은 한 화면 뒤로 간다")
    func goesBack() async {
        let (store, _) = makeStore(.success)

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }

    @Test("B6·B7. 저장하면 입력값을 보내고, 성공하면 오류 문구를 지우고 뒤로 간다")
    func savesAndGoesBack() async {
        let (store, client) = makeStore(.success)
        store.send(.newNicknameChanged("새닉"))
        await store.send(.saveFailed(.duplicated)).finish()

        await store.send(.saveTapped).finish()

        #expect(client.editedNicknames == ["새닉"])
        #expect(client.cachedNickname() == "새닉")
        #expect(store.state.errorMessage == nil)
        // 성공 결과가 시작한 이동은 finish 범위 밖이라 기록될 때까지 기다린다 (1-7 Q6)
        #expect(await waitUntil { navigator.actions == [.pop] })
    }

    @Test(
        "B8~B10. 서버가 거절하면 이유에 맞는 문구를 보여 주고 머문다",
        arguments: [
            (EditNicknameError.duplicated, "이미 사용 중인 닉네임입니다."),
            (.invalidFormat, "1~20자의 한글, 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."),
            (.empty, "닉네임을 입력해 주세요."),
        ]
    )
    func showsRejectionMessage(error: EditNicknameError, message: String) async {
        let (store, _) = makeStore(.init(editNicknameResult: .failure(error)))

        await store.send(.saveTapped).finish()

        #expect(store.state.errorMessage == message)
        #expect(navigator.actions.isEmpty)
    }

    @Test(
        "B11. 알 수 없는 코드·전송 실패는 화면을 바꾸지 않는다 (이전 문구 유지)",
        arguments: [
            EditNicknameError.unexpectedResponse, .transport(.offline), .transport(.sessionExpired),
        ]
    )
    func ignoresOtherFailures(error: EditNicknameError) async {
        let (store, _) = makeStore(.init(editNicknameResult: .failure(error)))
        await store.send(.saveFailed(.empty)).finish()

        await store.send(.saveTapped).finish()

        #expect(store.state.errorMessage == "닉네임을 입력해 주세요.")
        #expect(navigator.actions.isEmpty)
    }

    @Test("B5. 연속으로 저장해도 요청마다 보낸다 (레거시와 같음)")
    func sendsEveryTap() async {
        let (store, client) = makeStore(
            .init(editNicknameResult: .failure(.duplicated), delay: .milliseconds(50)))
        store.send(.newNicknameChanged("a"))

        let first = store.send(.saveTapped)
        let second = store.send(.saveTapped)
        await first.finish()
        await second.finish()

        #expect(client.editedNicknames == ["a", "a"])
    }
}
