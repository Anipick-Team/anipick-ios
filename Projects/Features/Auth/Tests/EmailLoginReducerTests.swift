import Analytics
import AuthClientInterface
import AuthClientTesting
import AuthInterface
import ClientCore
import FeatureTestSupport
import MVICore
import Testing
import os

@testable import AuthFeature

/// 동작 목록 EL1~EL12 (notes/2026-10-29-R-auth-01-email-login.md)과 1:1
@Suite("이메일 로그인", .timeLimit(.minutes(1)))
struct EmailLoginReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()
    private let completed = OSAllocatedUnfairLock(initialState: 0)

    private func makeStore(_ result: Result<EmailLoginResult, TransportError>) -> (
        Store<EmailLoginReducer>, MockAuthClient
    ) {
        let client = MockAuthClient(emailLoginResult: result)
        let store = Store(
            initialState: EmailLoginReducer.State(),
            reducer: EmailLoginReducer(
                authClient: client, navigator: navigator, analytics: tracker,
                onLoginCompleted: { [completed] in completed.withLock { $0 += 1 } })
        )
        return (store, client)
    }

    @Test(
        "EL1. 이메일을 바꿀 때마다 안내: 비면 입력 요청, 형식이 틀리면 형식 안내, 맞으면 없음 (앞뒤 공백 무시)",
        arguments: [
            ("", "이메일을 입력해주세요."), ("ani", "올바른 이메일 형식이 아닙니다."),
            ("ani@pick", "올바른 이메일 형식이 아닙니다."), (" ani@pick.com ", ""),
        ]
    )
    func emailGuide(email: String, guide: String) async {
        let (store, _) = makeStore(.failure(.offline))

        await store.send(.emailChanged(email)).finish()

        #expect(store.state.emailGuide == guide)
    }

    @Test(
        "EL2. 비밀번호를 바꿀 때마다 안내: 영문·숫자·특수문자를 하나씩 넣은 8~16자",
        arguments: [
            ("", "비밀번호를 입력해주세요."), ("abc12!", "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."),
            ("abcdefgh1", "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."), ("abcdefg1!", ""),
            ("abcdefghijklmn1!!", "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."),
        ]
    )
    func passwordGuide(password: String, guide: String) async {
        let (store, _) = makeStore(.failure(.offline))

        await store.send(.passwordChanged(password)).finish()

        #expect(store.state.passwordGuide == guide)
    }

    @Test("EL3. 로그인 버튼 상태는 비밀번호를 바꿀 때만 다시 계산한다 (이메일을 나중에 넣으면 비활성 그대로)")
    func loginEnabled() async {
        let (store, _) = makeStore(.failure(.offline))

        await store.send(.passwordChanged("pw")).finish()
        await store.send(.emailChanged("a@b.co")).finish()
        #expect(store.state.isLoginEnabled == false)
        await store.send(.passwordChanged("pw2")).finish()
        #expect(store.state.isLoginEnabled)
    }

    @Test("EL4. 눈 아이콘은 비밀번호 보기를 켜고 끈다")
    func visibility() async {
        let (store, _) = makeStore(.failure(.offline))

        await store.send(.passwordVisibilityTapped).finish()
        #expect(store.state.isPasswordVisible)
    }

    @Test("EL5·EL6. 로그인: 비활성이어도 보낸다. 성공하면 사용자 설정 → login 이벤트 → 로그인 완료")
    func loginSucceeds() async {
        let user = LoggedInUser(
            userId: 42, nickname: "n", hasAccessToken: true, reviewCompleted: nil)
        let (store, client) = makeStore(.success(.success(user)))
        await store.send(.emailChanged("a@b.co")).finish()

        await store.send(.loginTapped).finish()

        #expect(client.emailLogins == [.init(email: "a@b.co", password: "")])
        #expect(await waitUntil { completed.withLock { $0 } == 1 })
        #expect(tracker.events == [.login(method: "email")])
        #expect(tracker.nonFatals.isEmpty)
    }

    @Test("EL6·EL7·EL10. 빈 토큰·결과 없음·처리 안 한 코드는 로그인 이슈로 남긴다 (빈 토큰은 로그인은 진행)")
    func loginIssues() async {
        let empty = LoggedInUser(
            userId: nil, nickname: nil, hasAccessToken: false, reviewCompleted: nil)
        for (result, reason, completes) in [
            (EmailLoginResult.success(empty), "200 but empty accessToken", true),
            (.missingResult, "200 but result nil", false),
            (.unexpected(code: 999), "unhandled response code: 999", false),
        ] {
            let tracker = RecordingTracker()
            let completed = OSAllocatedUnfairLock(initialState: 0)
            let store = Store(
                initialState: EmailLoginReducer.State(),
                reducer: EmailLoginReducer(
                    authClient: MockAuthClient(emailLoginResult: .success(result)),
                    navigator: navigator,
                    analytics: tracker, onLoginCompleted: { completed.withLock { $0 += 1 } })
            )

            await store.send(.loginTapped).finish()

            #expect(await waitUntil { !tracker.nonFatals.isEmpty })
            #expect(tracker.nonFatals.first?.breadcrumb == "[Login][email] \(reason)")
            #expect(await waitUntil { completed.withLock { $0 } == (completes ? 1 : 0) })
        }
    }

    @Test(
        "EL8. 응답 코드별 안내 (안내는 응답을 받으면 먼저 모두 지운다)",
        arguments: [
            (
                EmailLoginResult.invalidPasswordFormat, "",
                "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요.", ""
            ),
            (.wrongCredentials, "", "", "이메일이나 비밀번호를 확인해주세요."),
            (.emptyPassword, "", "비밀번호를 입력해주세요.", ""),
            (.accountNotFound, "가입된 계정이 없습니다. 이메일을 다시 확인해주세요.", "", ""),
            (.emptyEmail, "이메일 주소를 입력해 주세요.", "", ""),
        ]
    )
    func codeGuides(result: EmailLoginResult, email: String, password: String, common: String) async
    {
        let (store, _) = makeStore(.success(result))
        await store.send(.emailChanged("x")).finish()

        await store.send(.loginTapped).finish()

        #expect(store.state.emailGuide == email)
        #expect(store.state.passwordGuide == password)
        #expect(store.state.commonGuide == common)
    }

    @Test("EL9. 탈퇴한 계정이면 팝업, 닫으면 팝업을 닫고 한 화면 뒤로")
    func withdrawn() async {
        let (store, _) = makeStore(.success(.withdrawn))

        await store.send(.loginTapped).finish()
        #expect(store.state.isWithdrawnPopupPresented)
        await store.send(.withdrawnPopupClosed).finish()

        #expect(store.state.isWithdrawnPopupPresented == false)
        #expect(navigator.actions == [.pop])
    }

    @Test("EL11. 전송에 실패하면 login_email 오류로 남기고 안내는 그대로 둔다")
    func transportFailure() async {
        let (store, _) = makeStore(.failure(.offline))
        await store.send(.emailChanged("x")).finish()

        await store.send(.loginTapped).finish()

        #expect(tracker.nonFatals.first?.breadcrumb.hasPrefix("[login_email] ") == true)
        #expect(store.state.emailGuide == "올바른 이메일 형식이 아닙니다.")
    }

    @Test("EL12. 회원가입·비밀번호 찾기로 가고, 뒤로는 pop")
    func navigation() async {
        let (store, _) = makeStore(.failure(.offline))

        await store.send(.signupTapped).finish()
        await store.send(.findPasswordTapped).finish()
        await store.send(.backTapped).finish()

        #expect(
            navigator.actions == [
                .push(AuthRoute.emailSignup), .push(AuthRoute.findPassword), .pop,
            ])
    }
}
