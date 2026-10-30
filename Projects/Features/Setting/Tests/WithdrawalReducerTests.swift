import FeatureTestSupport
import MVICore
import Testing
import UserClientInterface
import UserClientTesting

@testable import SettingFeature

/// 동작 목록 W1~W8 (notes/2026-10-19-R-setting-02-withdrawal.md)과 1:1
@Suite("회원 탈퇴", .timeLimit(.minutes(1)))
struct WithdrawalReducerTests {
    private let navigator = RecordingNavigator()

    private func makeStore(_ scenario: MockUserClient.Scenario) -> (
        Store<WithdrawalReducer>, MockUserClient
    ) {
        let client = MockUserClient(scenario)
        let store = Store(
            initialState: WithdrawalReducer.State(email: client.cachedEmail()),
            reducer: WithdrawalReducer(userClient: client, navigator: navigator)
        )
        return (store, client)
    }

    @Test("W2. 저장된 이메일을 @ 뒤에 U+200B를 넣어 보여 준다")
    func displaysEmail() {
        let (store, _) = makeStore(.init(email: "ani@pick.com"))

        #expect(store.state.displayedEmail == "ani@\u{200B}pick.com")
    }

    @Test("W1. 뒤로 버튼은 한 화면 뒤로 간다")
    func goesBack() async {
        let (store, _) = makeStore(.success)

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }

    @Test(
        "W5~W7. 탈퇴하기는 요청을 보내고, 결과와 무관하게 이 화면은 이동하지 않는다 (성공 시 이동은 Session)",
        arguments: [
            Result<Void, WithdrawalError>.success(()), .failure(.rejected),
            .failure(.transport(.offline)),
        ]
    )
    func withdraws(result: Result<Void, WithdrawalError>) async {
        let (store, client) = makeStore(.init(withdrawalResult: result))

        await store.send(.withdrawTapped).finish()

        #expect(client.withdrawalCount == 1)
        #expect(navigator.actions.isEmpty)
    }
}
