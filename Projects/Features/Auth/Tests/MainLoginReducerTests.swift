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

/// 동작 목록 ML1~ML12 (notes/2026-10-30-R-auth-05-main-login.md)과 1:1
@Suite("메인 로그인", .timeLimit(.minutes(1)))
struct MainLoginReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()
    private let completed = OSAllocatedUnfairLock(initialState: 0)
    private let opened = OSAllocatedUnfairLock(initialState: [URL]())

    private func makeStore(_ client: MockAuthClient) -> Store<MainLoginReducer> {
        return Store(
            initialState: MainLoginReducer.State(),
            reducer: MainLoginReducer(
                authClient: client, navigator: navigator, analytics: tracker,
                onLoginCompleted: { [completed] in completed.withLock { $0 += 1 } },
                openURL: { [opened] url in opened.withLock { $0.append(url) } })
        )
    }

    private func client(_ social: MockAuthClient.Social) -> MockAuthClient {
        let client = MockAuthClient()
        client.socialScenario = social
        return client
    }

    @Test("ML1·ML2·ML3. 카카오·구글·애플 토큰을 각 수단으로 서버에 보낸다")
    func sendsTokens() async {
        let client = client(.init())
        let store = makeStore(client)

        await store.send(.kakaoTapped).finish()
        await store.send(.googleTapped).finish()
        await store.send(.appleCompleted(.token("APPLE"))).finish()

        #expect(
            client.socialLogins
                == [
                    .init(provider: .kakao, code: "KAKAO"),
                    .init(provider: .google, code: "GOOGLE"),
                    .init(provider: .apple, code: "APPLE"),
                ])
    }

    @Test("ML4. SDK 실패: 사유가 있으면 로그인 이슈, 오류면 수단별 문맥의 비치명 오류. 서버에 보내지 않는다")
    func sdkFailures() async {
        let client = client(
            .init(
                kakaoToken: .failure(.sdk(NSError(domain: "K", code: 1))),
                googleToken: .failure(.issue("idToken nil or empty"))))
        let store = makeStore(client)

        await store.send(.kakaoTapped).finish()
        await store.send(.googleTapped).finish()
        await store.send(.appleCompleted(.emptyIdentityToken)).finish()
        await store.send(.appleCompleted(.credentialCastFailed)).finish()
        await store.send(.appleCompleted(.failed(NSError(domain: "A", code: 2)))).finish()

        #expect(client.socialLogins.isEmpty)
        let breadcrumbs = tracker.nonFatals.map(\.breadcrumb)
        #expect(breadcrumbs.count == 5)
        // SDK 오류 문구는 시스템 언어를 따르므로 문맥만 본다
        #expect(breadcrumbs.first?.hasPrefix("[login_kakao] ") == true)
        #expect(
            Array(breadcrumbs.dropFirst().prefix(3))
                == [
                    "[Login][google] idToken nil or empty", "[Login][apple] empty identityToken",
                    "[Login][apple] credential cast failed",
                ])
        #expect(breadcrumbs.last?.hasPrefix("[login_apple_authorization] ") == true)
    }

    @Test(
        "ML5·ML6. 성공: 사용자 설정 → login(수단) 이벤트 → 취향 평가를 마쳤거나 값이 없으면 로그인 완료", arguments: [true, nil])
    func succeeds(reviewCompleted: Bool?) async {
        let user = LoggedInUser(
            userId: 7, nickname: "n", hasAccessToken: true, reviewCompleted: reviewCompleted)
        let store = makeStore(client(.init(login: .success(.success(user)))))

        await store.send(.kakaoTapped).finish()

        #expect(await waitUntil { completed.withLock { $0 } == 1 })
        #expect(tracker.events == [.login(method: "kakao")])
        #expect(navigator.actions.isEmpty)
    }

    @Test("ML6. 취향 평가 전 사용자는 취향 선택으로, 빈 토큰은 로그인 이슈")
    func newUser() async {
        let user = LoggedInUser(
            userId: nil, nickname: nil, hasAccessToken: false, reviewCompleted: false)
        let store = makeStore(client(.init(login: .success(.success(user)))))

        await store.send(.googleTapped).finish()

        #expect(await waitUntil { navigator.actions == [.push(AuthRoute.preferenceSelection)] })
        #expect(tracker.nonFatals.first?.breadcrumb == "[Login][google] 200 but empty accessToken")
        #expect(completed.withLock { $0 } == 0)
    }

    @Test("ML7. 탈퇴 계정이면 팝업, 닫으면 닫힌다")
    func withdrawn() async {
        let store = makeStore(client(.init(login: .success(.withdrawn))))

        await store.send(.kakaoTapped).finish()
        #expect(store.state.isWithdrawnPopupPresented)
        await store.send(.withdrawnPopupClosed).finish()

        #expect(!store.state.isWithdrawnPopupPresented)
        #expect(navigator.actions.isEmpty)
    }

    @Test("ML8·ML9. 다른 수단으로 가입된 계정이면 안내 팝업. 확인은 이메일 계정만 이메일 로그인으로, 닫기는 닫기만")
    func existingAccount() async {
        let store = makeStore(client(.init(login: .success(.existingAccount(.email)))))
        await store.send(.kakaoTapped).finish()
        #expect(store.state.existingAccount == .email)
        await store.send(.existingAccountConfirmed).finish()
        #expect(store.state.existingAccount == nil)
        #expect(navigator.actions == [.push(AuthRoute.emailLogin)])

        let other = makeStore(client(.init(login: .success(.existingAccount(.apple)))))
        await other.send(.kakaoTapped).finish()
        await other.send(.existingAccountConfirmed).finish()
        await other.send(.kakaoTapped).finish()
        await other.send(.existingAccountClosed).finish()

        #expect(other.state.existingAccount == nil)
        #expect(navigator.actions == [.push(AuthRoute.emailLogin)])
    }

    @Test("ML10. 처리 안 한 코드는 로그인 이슈, 전송 실패는 login_social_{수단} 오류")
    func failures() async {
        let store = makeStore(client(.init(login: .success(.unexpected(code: 500)))))
        await store.send(.kakaoTapped).finish()
        let offline = makeStore(client(.init(login: .failure(.offline))))
        await offline.send(.appleCompleted(.token("T"))).finish()

        #expect(
            tracker.nonFatals.first?.breadcrumb == "[Login][kakao] unhandled response code: 500")
        #expect(tracker.nonFatals.last?.breadcrumb.hasPrefix("[login_social_apple] ") == true)
    }

    @Test("ML11·ML12. 이메일 가입·로그인으로 가고, 로그인 문제는 구글 설문을 연다")
    func links() async {
        let store = makeStore(client(.init()))

        await store.send(.emailSignupTapped).finish()
        await store.send(.emailLoginTapped).finish()
        await store.send(.problemTapped).finish()

        #expect(navigator.actions == [.push(AuthRoute.emailSignup), .push(AuthRoute.emailLogin)])
        #expect(opened.withLock { $0 } == [MainLoginReducer.problemFormURL])
    }
}
