import Analytics
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

/// 동작 목록 SU1~SU10 (notes/2026-10-29-R-auth-02-signup.md)과 1:1
@Suite("이메일 회원가입", .timeLimit(.minutes(1)))
struct EmailSignupReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()
    private let openedURLs = OSAllocatedUnfairLock(initialState: [URL]())

    private func makeStore(_ result: Result<EmailSignupResult, TransportError> = .success(.success))
        -> (Store<EmailSignupReducer>, MockAuthClient)
    {
        let client = MockAuthClient(signupResult: result)
        let store = Store(
            initialState: EmailSignupReducer.State(),
            reducer: EmailSignupReducer(
                authClient: client, navigator: navigator, analytics: tracker,
                openURL: { [openedURLs] url in openedURLs.withLock { $0.append(url) } })
        )
        return (store, client)
    }

    @Test("SU1. 이메일 안내는 로그인과 같다")
    func emailGuide() async {
        let (store, _) = makeStore()

        await store.send(.emailChanged("ani")).finish()

        #expect(store.state.emailGuide == "올바른 이메일 형식이 아닙니다.")
    }

    @Test(
        "SU2·SU3. 비밀번호: 비면 안내 없음, 형식이 틀리면 안내. 체크는 앞뒤 공백을 빼고 검사",
        arguments: [
            ("", "", false), ("abc", "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요.", false),
            ("abcdefg1!", "", true), (" abcdefg1! ", "", true),
        ]
    )
    func passwordGuide(password: String, guide: String, valid: Bool) async {
        let (store, _) = makeStore()

        await store.send(.passwordChanged(password)).finish()

        #expect(store.state.passwordGuide == guide)
        #expect(store.state.isPasswordValid == valid)
    }

    @Test("SU4. 모두 동의는 넷을 함께 켜고 끈다. 셋을 하나씩 켜면 모두 동의도 켜진다")
    func agreements() async {
        let (store, _) = makeStore()

        await store.send(.agreeAllTapped).finish()
        #expect(
            store.state.agreesOverFourteen && store.state.agreesTerms && store.state.agreesPrivacy)
        await store.send(.agreeAllTapped).finish()
        #expect(!store.state.agreesTerms)
        await store.send(.overFourteenTapped).finish()
        await store.send(.termsTapped).finish()
        #expect(!store.state.agreesAll)
        await store.send(.privacyTapped).finish()
        #expect(store.state.agreesAll)
    }

    @Test("SU5. 약관·개인정보 동의를 누르면 동의를 바꾸고 문서를 연다. 만 14세는 열지 않는다")
    func opensDocuments() async {
        let (store, _) = makeStore()

        await store.send(.overFourteenTapped).finish()
        await store.send(.termsTapped).finish()
        await store.send(.privacyTapped).finish()

        #expect(
            openedURLs.withLock { $0 } == [
                EmailSignupReducer.termsURL, EmailSignupReducer.privacyURL,
            ])
    }

    @Test("SU6. 가입 버튼은 이메일·비밀번호가 있고 모두 동의했을 때 활성")
    func enabled() async {
        let (store, _) = makeStore()
        await store.send(.emailChanged("a@b.co")).finish()
        await store.send(.passwordChanged("x")).finish()
        #expect(!store.state.isSignupEnabled)

        await store.send(.agreeAllTapped).finish()

        #expect(store.state.isSignupEnabled)
    }

    @Test("SU7. 가입: 이메일·비밀번호·모두 동의 여부를 보내고, 성공하면 사용자(userId 없음)·sign_up 이벤트 후 취향 선택으로")
    func signup() async {
        let (store, client) = makeStore()
        await store.send(.emailChanged("a@b.co")).finish()
        await store.send(.passwordChanged("pw1!pw1!")).finish()

        await store.send(.signupTapped).finish()

        #expect(
            client.emailSignups == [
                .init(email: "a@b.co", password: "pw1!pw1!", agreedToTerms: false)
            ])
        #expect(await waitUntil { navigator.actions == [.push(AuthRoute.preferenceSelection)] })
        #expect(tracker.events == [.signUp])
    }

    @Test("SU8·SU9. 이미 가입한 이메일이면 안내, 그 밖의 코드·전송 실패는 아무것도 하지 않는다")
    func failures() async {
        let (duplicated, _) = makeStore(.success(.duplicatedEmail))
        await duplicated.send(.signupTapped).finish()
        #expect(duplicated.state.emailGuide == "이미 가입한 이메일입니다.")

        let (other, _) = makeStore(.success(.unexpected(code: 500)))
        await other.send(.signupTapped).finish()
        let (offline, _) = makeStore(.failure(.offline))
        await offline.send(.signupTapped).finish()

        #expect(navigator.actions.isEmpty)
        #expect(tracker.events.isEmpty)
        #expect(tracker.nonFatals.isEmpty)
    }

    @Test("SU10. 뒤로는 pop")
    func back() async {
        let (store, _) = makeStore()

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }
}
