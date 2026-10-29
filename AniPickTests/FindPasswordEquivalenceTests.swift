//
//  FindPasswordEquivalenceTests.swift
//  AniPickTests
//
//  이관한 비밀번호 찾기(인증번호)·새 비밀번호 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Auth 3).
//

import AuthClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import AuthFeature

@MainActor
@Suite("비밀번호 찾기 ↔ 레거시", .serialized)
struct FindPasswordEquivalenceTests {
    private var legacyViewModel: ForgetPasswordViewModel {
        return ForgetPasswordViewModel(
            authUsecase: AuthUsecase(authRepository: AuthRepository(apiService: AuthAPIService())),
            navigationManager: NavigationManager())
    }

    private func findReducer() -> FindPasswordReducer {
        return FindPasswordReducer(
            authClient: MockAuthClient(), navigator: LegacyNavigator(navigationManager: NavigationManager()))
    }

    @Test("처음 화면이 같다")
    func initial() throws {
        #expect(
            try hostedSnapshot(AniPick.ForgetPasswordView(viewModel: legacyViewModel))
                == hostedSnapshot(FindPasswordView(state: .init(), reducer: findReducer())))
    }

    @Test("보낸 뒤(전송됨 타이머·남은 시간·안내·다음 활성)가 같다")
    func sent() throws {
        let viewModel = legacyViewModel
        viewModel.emailString = "ani@pick.com"
        viewModel.verificationCode = "1234"
        viewModel.emailGuideText = ""
        viewModel.validNumButtonText = "전송됨 00:29"
        viewModel.isValidNumButtonEnabled = false
        viewModel.timerCount = "2:59"
        viewModel.validNumeberGuideText = "인증번호가 올바르지 않습니다."

        var state = FindPasswordReducer.State()
        state.email = "ani@pick.com"
        state.code = "1234"
        state.isNextEnabled = true
        state.emailGuide = ""
        state.sendButtonTitle = "전송됨 00:29"
        state.isSendEnabled = false
        state.timerText = "2:59"
        state.codeGuide = "인증번호가 올바르지 않습니다."

        #expect(
            try hostedSnapshot(AniPick.ForgetPasswordView(viewModel: viewModel))
                == hostedSnapshot(FindPasswordView(state: state, reducer: findReducer())))
    }

    @Test("통제: 남은 시간이 다르면 픽셀이 다르다")
    func detectsTimer() throws {
        let viewModel = legacyViewModel
        viewModel.timerCount = "2:59"
        var state = FindPasswordReducer.State()
        state.timerText = "2:58"

        #expect(
            try hostedSnapshot(AniPick.ForgetPasswordView(viewModel: viewModel))
                != hostedSnapshot(FindPasswordView(state: state, reducer: findReducer())))
    }

    @Test("새 비밀번호 화면(입력·안내)이 같다", arguments: [("", ""), ("abc", "abc"), ("abcdefg1!", "abcdefg1!")])
    func resetPassword(new: String, confirmation: String) throws {
        let viewModel = legacyViewModel
        viewModel.newPassword = new
        viewModel.checkNewPassword = confirmation
        let reducer = ResetPasswordReducer(
            authClient: MockAuthClient(), navigator: LegacyNavigator(navigationManager: NavigationManager()))
        var state = ResetPasswordReducer.State()
        _ = reducer.reduce(into: &state, intent: .newPasswordChanged(new))
        _ = reducer.reduce(into: &state, intent: .confirmationChanged(confirmation))

        #expect(
            try hostedSnapshot(NewPasswordView(viewModel: viewModel).environmentObject(NavigationManager()))
                == hostedSnapshot(ResetPasswordView(state: state, reducer: reducer)))
    }
}
