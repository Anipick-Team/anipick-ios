//
//  MainLoginEquivalenceTests.swift
//  AniPickTests
//
//  이관한 메인 로그인 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Auth 5).
//

import AuthClientInterface
import AuthClientTesting
import FeatureTestSupport
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import AuthFeature

@MainActor
@Suite("메인 로그인 ↔ 레거시", .serialized)
struct MainLoginEquivalenceTests {
    private func legacy(withdrawn: Bool = false, existing: ExistingAccountType? = nil) -> some View {
        let viewModel = MainLoginViewModel(
            authUsecase: AuthUsecase(authRepository: AuthRepository(apiService: AuthAPIService())),
            navigationManager: NavigationManager())
        viewModel.isShowWithdrawlUserPopup = withdrawn
        viewModel.existingAccountType = existing
        return AniPick.MainLoginView(viewModel: viewModel)
    }

    private func new(withdrawn: Bool = false, existing: ExistingAccount? = nil) -> some View {
        var state = MainLoginReducer.State()
        state.isWithdrawnPopupPresented = withdrawn
        state.existingAccount = existing
        return AuthFeature.MainLoginView(
            state: state,
            reducer: MainLoginReducer(
                authClient: MockAuthClient(), navigator: LegacyNavigator(navigationManager: NavigationManager()),
                analytics: RecordingTracker(), onLoginCompleted: {}, openURL: { _ in }))
    }

    @Test("처음 화면(카카오·구글·애플 버튼 포함)이 같다")
    func initial() throws {
        #expect(try hostedSnapshot(legacy()) == hostedSnapshot(new()))
    }

    @Test("탈퇴 계정 팝업이 같다")
    func withdrawn() throws {
        #expect(try hostedSnapshot(legacy(withdrawn: true)) == hostedSnapshot(new(withdrawn: true)))
    }

    @Test(
        "다른 수단으로 가입된 계정 팝업이 같다",
        arguments: [
            (ExistingAccountType.email, ExistingAccount.email), (.kakao, .kakao), (.google, .google),
            (.apple, .apple),
        ]
    )
    func existing(legacyType: ExistingAccountType, type: ExistingAccount) throws {
        #expect(try hostedSnapshot(legacy(existing: legacyType)) == hostedSnapshot(new(existing: type)))
    }

    @Test("통제: 팝업 수단이 다르면 픽셀이 다르다")
    func detectsAccount() throws {
        #expect(try hostedSnapshot(legacy(existing: .kakao)) != hostedSnapshot(new(existing: .google)))
    }
}
