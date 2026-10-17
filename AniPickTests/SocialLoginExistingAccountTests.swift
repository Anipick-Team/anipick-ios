//
//  SocialLoginExistingAccountTests.swift
//  AniPickTests
//
//  서버 PR anipick-backend#421 — 소셜 로그인 중복 계정 에러 코드(133~136)별 기존 가입 수단 판정
//

import Testing
@testable import AniPick

@MainActor
struct SocialLoginExistingAccountTests {

    private let navigationManager = NavigationManager()

    private func makeViewModel(usecase: MockAuthUsecase) -> MainLoginViewModel {
        return MainLoginViewModel(authUsecase: usecase, navigationManager: navigationManager)
    }

    /// `NavigationManager.push` 는 내부에서 Task 로 경로를 추가하므로 반영될 때까지 양보한다.
    private func settleNavigation() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }

    // MARK: - S1~S4 응답 코드 → 기존 가입 수단

    @Test("소셜 로그인 응답 코드가 기존 가입 수단으로 판정된다",
          arguments: [
            (133, ExistingAccountType.email),
            (134, ExistingAccountType.kakao),
            (135, ExistingAccountType.google),
            (136, ExistingAccountType.apple)
          ])
    func socialLoginErrorCodeResolvesExistingAccountType(code: Int, expected: ExistingAccountType) async {
        let viewModel = makeViewModel(usecase: MockAuthUsecase(code: code))

        await viewModel.postSocialLogin(provider: .kakao, code: "token")

        #expect(viewModel.existingAccountType == expected)
    }

    // MARK: - 파생 케이스

    @Test("정의되지 않은 코드는 기존 가입 수단으로 판정되지 않는다", arguments: [131, 132, 137, 200])
    func unknownCodeHasNoExistingAccountType(code: Int) {
        #expect(ExistingAccountType(errorCode: code) == nil)
    }

    @Test("탈퇴 계정(132)은 탈퇴로만 처리된다")
    func withdrawnAccountIsHandledAsWithdrawnOnly() async {
        let viewModel = makeViewModel(usecase: MockAuthUsecase(code: 132))

        await viewModel.postSocialLogin(provider: .google, code: "token")

        #expect(viewModel.isShowWithdrawlUserPopup)
        #expect(viewModel.existingAccountType == nil)
    }

    @Test("처리되지 않은 코드(131·137)는 기존 가입 수단도 탈퇴도 아니다", arguments: [131, 137])
    func unhandledCodeIsIgnored(code: Int) async {
        let viewModel = makeViewModel(usecase: MockAuthUsecase(code: code))

        await viewModel.postSocialLogin(provider: .apple, code: "token")

        #expect(viewModel.existingAccountType == nil)
        #expect(!viewModel.isShowWithdrawlUserPopup)
    }

    @Test("소셜 로그인 요청이 실패하면 판정도 이동도 없다")
    func requestFailureResolvesNothing() async {
        let viewModel = makeViewModel(usecase: MockAuthUsecase(socialLoginResult: .failure(MockAuthUsecaseError.network)))

        await viewModel.postSocialLogin(provider: .kakao, code: "token")
        await settleNavigation()

        #expect(viewModel.existingAccountType == nil)
        #expect(navigationManager.path.isEmpty)
    }
}
