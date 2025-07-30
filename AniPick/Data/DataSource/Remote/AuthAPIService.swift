//
//  AuthAPIService.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//
import Alamofire
import SwiftUI

final class AuthAPIService {
    static let shared = AuthAPIService()
    let session = Session(interceptor: TokenInterceptor.shared)
    private func requestAPI<T: Decodable>(_ api: AuthAPI) async throws -> T {
        return try await NetworkManager.request(
            path: api.path,
            method: api.method,
            parameters: api.parameters,
            headers: api.header
        )
    }
}

extension AuthAPIService {
    func postSocialLogin(provider: String, request: SocialLoginRequest) async throws -> LoginResponse {
        try await requestAPI(.socialLogin(provider: provider, request: request))
    }
    
    func postRefreshToken(refreshToken: String) async throws -> LoginResponse {
        try await requestAPI(.refreshToken(refreshToken: refreshToken))
    }
    
    func postLogout(accessToken: String) async throws -> BaseResponse {
        try await requestAPI(.logout(accessToken: accessToken))
    }
    
    func postRefreshToken(
          refreshToken: String,
          completion: @escaping (Result<RefreshResponse, Error>) -> Void
      ) {
          let api = AuthAPI.refreshToken(refreshToken: refreshToken)
          
          AF.request(
              NetworkManager.baseUrl + api.path,
              method: api.method,
              parameters: api.parameters,
              encoding: JSONEncoding.default,
              headers: api.header
          )
          .validate()
          .cURLDescription { description in
              DLog("\(description)")
          }
          .responseDecodable(of: RefreshResponse.self) { response in
              switch response.result {
              case .success(let value):
                  completion(.success(value))
                  DLog("refreshToken에서 성공적으로 받아옴 - \(value)")
//                  if value.code != 200 {
//                      DispatchQueue.main.async {
//                          DLog("refreshToken 실패Login 화면으로 이동이동 - \(value)")
//                          NavigationManager.shared.popToRoot()
//                          NavigationManager.shared.push(route: .mainLoginView)
//                      }
//                  }
              case .failure(let error):
                  completion(.failure(error))
                  DLog("refreshToken 만료 실패 - \(error)")
//                  DispatchQueue.main.async {
//                      DLog("refreshToken 실패Login 화면으로 이동이동 - \(error)")
//                      NavigationManager.shared.popToRoot()
//                      NavigationManager.shared.push(route: .mainLoginView)
//                  }
              }
          }
      }
  
}

extension AuthAPIService {
    func postEmailSignup(request: EmailSignupRequest) async throws -> LoginResponse {
        try await requestAPI(.emailSignup(request: request))
    }
    
    func postEmailLogin(request: EmailLoginRequest) async throws -> LoginResponse {
        try await requestAPI(.emailLogin(request: request))
    }
}

extension AuthAPIService {
    func sendEmailVerificationCode(email: String) async throws -> BaseResponse {
        try await requestAPI(.sendEmailVerificationCode(email: email))
    }
    
    func verifyEmailVerificationCode(request: VerifyVerificationCodeRequest) async throws -> BaseResponse {
        try await requestAPI(.verifyEmailVerificationCode(request: request))
    }
    
    func resetPassword(request: ResetPasswordRequest) async throws -> BaseResponse {
        try await requestAPI(.resetPassword(request: request))
    }
}
