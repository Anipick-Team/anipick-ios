import AuthClientInterface
import AuthClientTesting
import AuthInterface
import ClientCore
import FeatureTestSupport
import Foundation
import MVICore
import Testing
import os

@testable import AuthFeature

/// 동작 목록 FP1~FP12, RP1~RP6 (notes/2026-10-29-R-auth-03-find-password.md)과 1:1
@Suite("비밀번호 찾기", .timeLimit(.minutes(1)))
struct FindPasswordReducerTests {
    private let navigator = RecordingNavigator()
    private let clock = OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 1_000))

    private func makeStore(_ client: MockAuthClient = MockAuthClient()) -> Store<
        FindPasswordReducer
    > {
        return Store(
            initialState: FindPasswordReducer.State(),
            reducer: FindPasswordReducer(
                authClient: client, navigator: navigator,
                now: { [clock] in clock.withLock { $0 } }, tickInterval: .milliseconds(5))
        )
    }

    private func advance(_ seconds: TimeInterval) {
        clock.withLock { $0 = $0.addingTimeInterval(seconds) }
    }

    @Test("FP1. 처음에는 이메일 입력 안내가 보이고, 이메일을 바꾸면 로그인과 같은 안내")
    func emailGuide() async {
        let store = makeStore()
        #expect(store.state.emailGuide == "이메일을 입력해주세요.")

        await store.send(.emailChanged("a@b.co")).finish()

        #expect(store.state.emailGuide == "")
    }

    @Test("FP2·FP3. 인증번호 받기: 누르면 비활성·전송중, 안내를 지우고 이메일로 보낸다")
    func sendStarts() async {
        let client = MockAuthClient()
        client.findPasswordScenario = .init(send: .success(.unexpected(code: 500)))
        let store = makeStore(client)
        await store.send(.emailChanged("a@b.co")).finish()

        await store.send(.sendTapped).finish()

        #expect(client.findPasswordCalls == [.send(email: "a@b.co")])
        // FP6: 처리 안 한 코드면 전송중·비활성 그대로
        #expect(store.state.sendButtonTitle == "전송중...")
        #expect(store.state.isSendEnabled == false)
    }

    @Test("FP4·FP5·FP7. 보내면 30초 재전송 대기(전송됨 mm:ss)와 3분 입력 제한(m:ss)이 흐르고, 끝나면 재전송·만료 안내")
    func timers() async {
        let store = makeStore()
        await store.send(.sendTapped).finish()
        #expect(store.state.sendButtonTitle == "전송됨 00:30")
        #expect(store.state.timerText == "3:00")
        #expect(store.state.isSendEnabled == false)

        advance(12)
        #expect(
            await waitUntil {
                store.state.sendButtonTitle == "전송됨 00:18" && store.state.timerText == "2:48"
            })
        advance(20)
        #expect(await waitUntil { store.state.sendButtonTitle == "인증번호 재전송" })
        #expect(store.state.isSendEnabled)
        advance(200)
        #expect(await waitUntil { store.state.timerText == "0:00" })
        #expect(store.state.codeGuide == "유효 시간이 만료되었습니다. 재발송 후 다시 시도해주세요.")
    }

    @Test(
        "FP6. 보내기 실패 코드: 버튼을 되살리고 이메일 안내",
        arguments: [
            (SendCodeResult.accountNotFound, "해당 이메일로 가입된 계정이 없습니다. 다시 확인해주세요."),
            (.invalidEmail, "올바른 이메일 형식이 아닙니다."), (.emptyEmail, "이메일 주소를 입력해 주세요."),
        ]
    )
    func sendFailures(result: SendCodeResult, guide: String) async {
        let client = MockAuthClient()
        client.findPasswordScenario = .init(send: .success(result))
        let store = makeStore(client)

        await store.send(.sendTapped).finish()

        #expect(store.state.emailGuide == guide)
        #expect(store.state.isSendEnabled)
        #expect(store.state.sendButtonTitle == "인증번호 받기")
    }

    @Test("FP8. 전송 실패면 버튼만 되살린다 (안내는 그대로)")
    func sendTransportFailure() async {
        let client = MockAuthClient()
        client.findPasswordScenario = .init(send: .failure(.offline))
        let store = makeStore(client)

        await store.send(.sendTapped).finish()

        #expect(store.state.isSendEnabled)
        #expect(store.state.emailGuide == "이메일을 입력해주세요.")
    }

    @Test("FP9·FP10. 다음: 인증번호가 있어야 활성. 맞으면 새 비밀번호로")
    func verify() async {
        let client = MockAuthClient()
        let store = makeStore(client)
        await store.send(.emailChanged("a@b.co")).finish()
        await store.send(.codeChanged("1234")).finish()
        #expect(store.state.isNextEnabled)

        await store.send(.nextTapped).finish()

        #expect(client.findPasswordCalls == [.verify(email: "a@b.co", code: "1234")])
        #expect(await waitUntil { navigator.actions == [.push(AuthRoute.resetPassword)] })
    }

    @Test(
        "FP11. 인증 실패 안내",
        arguments: [
            (VerifyCodeResult.emptyCode, "수신하신 인증번호를 입력해 주세요."), (.wrongCode, "인증번호가 올바르지 않습니다."),
            (.expired, "유효 시간이 만료되었습니다. 재발송 후 다시 시도해주세요."), (.unexpected(code: 1), ""),
        ]
    )
    func verifyFailures(result: VerifyCodeResult, guide: String) async {
        let client = MockAuthClient()
        client.findPasswordScenario = .init(verify: .success(result))
        let store = makeStore(client)

        await store.send(.nextTapped).finish()

        #expect(store.state.codeGuide == guide)
        #expect(navigator.actions.isEmpty)
    }

    @Test("FP12. 뒤로는 pop")
    func back() async {
        await makeStore().send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }
}

@Suite("새 비밀번호", .timeLimit(.minutes(1)))
struct ResetPasswordReducerTests {
    private let navigator = RecordingNavigator()

    private func makeStore(_ client: MockAuthClient = MockAuthClient()) -> Store<
        ResetPasswordReducer
    > {
        return Store(
            initialState: ResetPasswordReducer.State(),
            reducer: ResetPasswordReducer(authClient: client, navigator: navigator))
    }

    @Test("RP1·RP2. 버튼은 확인란만 보고 켠다. 확인란 안내는 공백을 자르지 않고 검사, 새 비밀번호 안내는 계산만 한다")
    func inputs() async {
        let store = makeStore()

        await store.send(.newPasswordChanged("abc")).finish()
        #expect(store.state.newPasswordGuide.isEmpty == false)
        #expect(!store.state.isSubmitEnabled)
        // 끝의 공백이 특수문자로 세어진다 — 잘랐다면 특수문자가 없어 안내가 떠야 한다
        await store.send(.confirmationChanged("abcdefg1 ")).finish()

        #expect(store.state.isSubmitEnabled)
        #expect(store.state.confirmationGuide == "")
        await store.send(.confirmationChanged("abc")).finish()
        #expect(store.state.confirmationGuide == "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요.")
    }

    @Test("RP3. 바꾸면 메인 로그인을 push한다")
    func succeeds() async {
        let client = MockAuthClient()
        let store = makeStore(client)
        await store.send(.newPasswordChanged("n")).finish()
        await store.send(.confirmationChanged("c")).finish()

        await store.send(.submitTapped).finish()

        #expect(client.findPasswordCalls == [.reset(newPassword: "n", confirmation: "c")])
        #expect(await waitUntil { navigator.actions == [.push(AuthRoute.mainLogin)] })
    }

    @Test("RP4·RP5. 실패 코드면 일치하지 않는다는 안내, 전송 실패는 아무것도 하지 않는다")
    func failures() async {
        let rejected = MockAuthClient()
        rejected.findPasswordScenario = .init(reset: .success(false))
        let store = makeStore(rejected)
        await store.send(.submitTapped).finish()
        #expect(store.state.confirmationGuide == "비밀번호가 일치하지 않습니다.")

        let offline = MockAuthClient()
        offline.findPasswordScenario = .init(reset: .failure(.offline))
        let other = makeStore(offline)
        await other.send(.submitTapped).finish()
        #expect(other.state.confirmationGuide == "")
        #expect(navigator.actions.isEmpty)
    }

    @Test("RP6. 눈 아이콘은 각 입력란 보기를 따로 켠다")
    func visibility() async {
        let store = makeStore()

        await store.send(.confirmationVisibilityTapped).finish()

        #expect(store.state.isConfirmationVisible)
        #expect(!store.state.isNewPasswordVisible)
    }
}
