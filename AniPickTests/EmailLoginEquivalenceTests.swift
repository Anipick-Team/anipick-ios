//
//  EmailLoginEquivalenceTests.swift
//  AniPickTests
//
//  이관한 이메일 로그인 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Auth 1).
//

import AuthClientTesting
import FeatureTestSupport
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import AuthFeature

@MainActor
@Suite("이메일 로그인 ↔ 레거시", .serialized)
struct EmailLoginEquivalenceTests {
    private func legacy(email: String = "", password: String = "", withdrawn: Bool = false) -> some View {
        let viewModel = EmailLoginViewModel(
            authUsecase: AuthUsecase(authRepository: AuthRepository(apiService: AuthAPIService())),
            navigationManager: NavigationManager())
        // didSet이 안내 문구를 계산한다 (레거시와 같은 입력 순서)
        viewModel.emailString = email
        viewModel.passwordString = password
        viewModel.isShowWithdrawlUserPopup = withdrawn
        return AniPick.EmailLoginView(viewModel: viewModel).environmentObject(NavigationManager())
    }

    private func new(email: String = "", password: String = "", withdrawn: Bool = false) -> some View {
        let reducer = EmailLoginReducer(
            authClient: MockAuthClient(), navigator: LegacyNavigator(navigationManager: NavigationManager()),
            analytics: RecordingTracker(), onLoginCompleted: {})
        var state = EmailLoginReducer.State()
        _ = reducer.reduce(into: &state, intent: .emailChanged(email))
        _ = reducer.reduce(into: &state, intent: .passwordChanged(password))
        state.isWithdrawnPopupPresented = withdrawn
        return AuthFeature.EmailLoginView(state: state, reducer: reducer)
    }

    @Test(
        "입력에 따른 안내·버튼 상태가 같다",
        arguments: [("", ""), ("ani", "abc"), ("ani@pick.com", "abcdefg1!"), ("ani@pick.com", "")]
    )
    func inputs(email: String, password: String) throws {
        #expect(
            try hostedSnapshot(legacy(email: email, password: password))
                == hostedSnapshot(new(email: email, password: password)))
    }

    @Test("탈퇴 계정 팝업이 같다")
    func withdrawnPopup() throws {
        #expect(try hostedSnapshot(legacy(withdrawn: true)) == hostedSnapshot(new(withdrawn: true)))
    }

    @Test("통제: 안내 문구가 다르면 픽셀이 다르다")
    func detectsGuide() throws {
        #expect(try hostedSnapshot(legacy(email: "ani")) != hostedSnapshot(new(email: "ani@pick.com")))
    }

    @Test("로그인 문제 화면이 같다")
    func loginProblem() throws {
        #expect(try hostedSnapshot(AniPick.LoginProblemView()) == hostedSnapshot(AuthFeature.LoginProblemView()))
    }
}
