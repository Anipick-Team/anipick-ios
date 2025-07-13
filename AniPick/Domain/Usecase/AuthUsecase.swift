//
//  AuthUsecase.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

protocol AuthUsecaseProtocol {
    func postSocialLogin(provider: LoginButtonProvider, request: SocialLoginRequest) async throws -> LoginResponse
    func postRefreshToken(refreshToken: String) async throws -> LoginResponse
    func postLogout(accessToken: String) async throws -> BaseResponse
    
    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse
    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse
    
    func sendEmailVerificationCode(email: String) async throws -> BaseResponse
    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse
    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse
}
struct AuthUsecase: AuthUsecaseProtocol {
    let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
}

extension AuthUsecase {
    func postSocialLogin(provider: LoginButtonProvider, request: SocialLoginRequest) async throws -> LoginResponse {
        try await authRepository.postSocialLogin(provider: provider.rawValue, request: request)
    }
    
    func postRefreshToken(refreshToken: String) async throws -> LoginResponse {
        try await authRepository.postRefreshToken(refreshToken: refreshToken)
    }
    
    func postLogout(accessToken: String) async throws -> BaseResponse {
        try await authRepository.postLogout(accessToken: accessToken)
    }
}

extension AuthUsecase {
    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse {
        try await authRepository.postEmailSignup(request: request)
    }
    
    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse {
        try await authRepository.postEmailLogin(request: request)
    }
}

extension AuthUsecase {
    func sendEmailVerificationCode(email: String) async throws -> BaseResponse {
        try await authRepository.sendEmailVerificationCode(email: email)
    }
    
    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse {
        try await authRepository.verifyEmailVerificationCode(request: request)
    }
    
    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse {
        try await authRepository.resetPassword(request: request)
    }
}
