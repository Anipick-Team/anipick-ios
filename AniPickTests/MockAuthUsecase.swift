//
//  MockAuthUsecase.swift
//  AniPickTests
//

@testable import AniPick

enum MockAuthUsecaseError: Error {
    case unused
    case network
}

final class MockAuthUsecase: AuthUsecaseProtocol {
    var socialLoginResult: Result<LoginResponse, Error>

    init(socialLoginResult: Result<LoginResponse, Error>) {
        self.socialLoginResult = socialLoginResult
    }

    convenience init(code: Int) {
        self.init(socialLoginResult: .success(LoginResponse(code: code, value: "", result: nil)))
    }

    func postSocialLogin(provider: LoginButtonProvider, request: SocialLoginRequest) async throws -> LoginResponse {
        return try socialLoginResult.get()
    }

    func postRefreshToken(refreshToken: String) async throws -> LoginResponse {
        throw MockAuthUsecaseError.unused
    }

    func postLogout(accessToken: String) async throws -> BaseResponse {
        throw MockAuthUsecaseError.unused
    }

    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse {
        throw MockAuthUsecaseError.unused
    }

    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse {
        throw MockAuthUsecaseError.unused
    }

    func sendEmailVerificationCode(email: String) async throws -> BaseResponse {
        throw MockAuthUsecaseError.unused
    }

    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse {
        throw MockAuthUsecaseError.unused
    }

    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse {
        throw MockAuthUsecaseError.unused
    }
}
