//
//  AuthAPI.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//
import Alamofire

enum AuthAPI {
    case socialLogin(provider: String, request: SocialLoginRequest)
    case refreshToken(refreshToken: String)
    case logout(accessToken: String)
    
    case emailSignup(request: EmailSignupRequest)
    case emailLogin(request: EmailLoginRequest)
    
    case sendEmailVerificationCode(email: String)
    case verifyEmailVerificationCode(request: VerifyVerificationCodeRequest)
    case resetPassword(request: ResetPasswordRequest)

    var path: String {
        switch self {
        case let .socialLogin(provider, _):
            return "api/oauth/\(provider)/callback"
        case .refreshToken:
            return "api/tokens/refresh"
        case .logout:
            return "api/users/logout"
            

        case .emailSignup:
            return "api/users/signup"
        case .emailLogin:
            return "api/users/login"
        
    
        case .sendEmailVerificationCode:
            return "api/auth/email/send"
        case .verifyEmailVerificationCode:
            return "api/auth/email/verify"
        case .resetPassword:
            return "api/auth/password/reset"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .socialLogin:
            return .post
        case .refreshToken:
            return .post
        case .logout:
            return .post
            
        case .emailSignup:
            return .post
        case .emailLogin:
            return .post
            
        case .sendEmailVerificationCode:
            return .post
        case .verifyEmailVerificationCode:
            return .post
        case .resetPassword:
            return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .socialLogin(_, request):
            return try? request.toDictionary()
            
        case .refreshToken, .logout:
            return nil
            
        case let .emailSignup(request):
            return try? request.toDictionary()
            
        case let .emailLogin(request):
            return try? request.toDictionary()
            
        case let .sendEmailVerificationCode(email):
            return ["email": email]
            
        case let .verifyEmailVerificationCode(request):
            return try? request.toDictionary()
            
        case let .resetPassword(request):
            return try? request.toDictionary()
        }
    }

    var header: HTTPHeaders {
        switch self {
        case .socialLogin, .emailSignup, .emailLogin, .sendEmailVerificationCode, .verifyEmailVerificationCode, .resetPassword:
            return ["Content-Type": "application/json"]
            
            // TODO: UserDefaults 로 바로 가져오는 로직 생성
        case let .refreshToken(refreshToken):
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getRefreshToken())"
            ]
        case let .logout(accessToken):
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"
            ]
        }
    }
}
