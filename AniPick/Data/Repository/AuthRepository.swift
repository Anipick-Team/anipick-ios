//
//  AuthRepository.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

protocol AuthRepositoryProtocol {
    func postSocialLogin(provider: String, request: SocialLoginRequest) async throws -> LoginResponse
    func postRefreshToken(refreshToken: String) async throws -> LoginResponse
    func postLogout(accessToken: String) async throws -> BaseResponse
    
    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse
    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse
    
    func sendEmailVerificationCode(email: String) async throws -> BaseResponse
    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse
    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse
}

struct AuthRepository: AuthRepositoryProtocol {
    let apiService: AuthAPIService
    
    init(apiService: AuthAPIService) {
        self.apiService = apiService
    }
}

extension AuthRepository {
    func postSocialLogin(provider: String, request: SocialLoginRequest) async throws -> LoginResponse {
        try await apiService.postSocialLogin(provider: provider, request: request)
    }
    
    func postRefreshToken(refreshToken: String) async throws -> LoginResponse {
        try await apiService.postRefreshToken(refreshToken: refreshToken)
    }
    
    func postLogout(accessToken: String) async throws -> BaseResponse {
        try await apiService.postLogout(accessToken: accessToken)
    }
}

extension AuthRepository {
    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse {
        try await apiService.postEmailSignup(request: request)
    }
    
    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse {
        try await apiService.postEmailLogin(request: request)
    }
}

extension AuthRepository {
    func sendEmailVerificationCode(email: String) async throws -> BaseResponse {
        try await apiService.sendEmailVerificationCode(email: email)
    }
    
    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse {
        try await apiService.verifyEmailVerificationCode(request: request)
    }
    
    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse {
        try await apiService.resetPassword(request: request)
    }
}
