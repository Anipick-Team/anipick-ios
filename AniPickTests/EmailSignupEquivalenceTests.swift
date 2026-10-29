//
//  EmailSignupEquivalenceTests.swift
//  AniPickTests
//
//  이관한 이메일 회원가입 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Auth 2).
//  내용이 ScrollView라 창에 올려 그린다.
//

import AuthClientTesting
import FeatureTestSupport
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import AuthFeature

@MainActor
@Suite("이메일 회원가입 ↔ 레거시", .serialized)
struct EmailSignupEquivalenceTests {
    struct Input: Sendable {
        var email = ""
        var password = ""
        var agreeAll = false
        var overFourteen = false
    }

    private func legacy(_ input: Input) -> some View {
        let viewModel = EmailSignupViewModel(
            authUsecase: AuthUsecase(authRepository: AuthRepository(apiService: AuthAPIService())),
            navigationManager: NavigationManager())
        viewModel.emailString = input.email
        viewModel.passwordString = input.password
        if input.agreeAll {
            viewModel.toggleAllAgreement()
        }
        if input.overFourteen {
            viewModel.toggleOverFourteen()
        }
        return AniPick.EmailSignupView(viewModel: viewModel).environmentObject(NavigationManager())
    }

    private func new(_ input: Input) -> some View {
        let reducer = EmailSignupReducer(
            authClient: MockAuthClient(), navigator: LegacyNavigator(navigationManager: NavigationManager()),
            analytics: RecordingTracker(), openURL: { _ in })
        var state = EmailSignupReducer.State()
        _ = reducer.reduce(into: &state, intent: .emailChanged(input.email))
        _ = reducer.reduce(into: &state, intent: .passwordChanged(input.password))
        if input.agreeAll {
            _ = reducer.reduce(into: &state, intent: .agreeAllTapped)
        }
        if input.overFourteen {
            _ = reducer.reduce(into: &state, intent: .overFourteenTapped)
        }
        return AuthFeature.EmailSignupView(state: state, reducer: reducer)
    }

    @Test(
        "입력·동의 상태가 같다",
        arguments: [
            Input(), Input(email: "ani", password: "abc"),
            Input(email: "ani@pick.com", password: "abcdefg1!", agreeAll: true),
            Input(email: "ani@pick.com", password: "", overFourteen: true),
        ]
    )
    func states(input: Input) throws {
        #expect(try hostedSnapshot(legacy(input)) == hostedSnapshot(new(input)))
    }

    @Test("통제: 동의 상태가 다르면 픽셀이 다르다")
    func detectsAgreement() throws {
        #expect(try hostedSnapshot(legacy(Input())) != hostedSnapshot(new(Input(agreeAll: true))))
    }
}
