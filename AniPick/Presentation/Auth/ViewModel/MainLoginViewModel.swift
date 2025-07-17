//
//  MainLoginViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI
import KakaoSDKUser
import GoogleSignIn
import GoogleSignInSwift
import Alamofire
import AuthenticationServices

@MainActor
class MainLoginViewModel: ObservableObject {
    
    @Published var moveToEmailSignupView: Bool = false
  //  @Published var navigationPath = NavigationPath()
    
    @Published var isSignedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    
    var kakaoToken: String = ""
    
    @Published var loginResponse: LoginResponse?
    
    private let authUsecase: AuthUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(authUsecase: AuthUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.authUsecase = authUsecase
        self.navigationManager = navigationManager
    }
    
    private let baseUrl = "http://118.36.154.101:8080"

}

extension MainLoginViewModel {
    
    func testtest() {
        self.navigationManager.push(route: .content)
    }
    func tappedEmailSignup() {
        navigationManager.push(route: AppRoute.emailSignup)
    }
    
    func tappedEmailLogin() {
        navigationManager.push(route: AppRoute.emailLogin)
    }
    func getKakaoAccessToken() {
        DLog("Tapped kakao Button")
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { [self] (oauthToken, error) in
                DLog("\(String(describing: oauthToken))")
                let code = oauthToken?.accessToken ?? ""
                Task {
                    await self.postSocialLogin(provider: .kakao, code: code)
                }
            }
        } else {
            // 2. 카카오계정 웹 로그인
            DLog("Kakao 로그인 값 받아오는 로직 실패-")
            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
               // handleLogin(oauthToken, error)
                DLog("Kakao 로그인 값 받아오는 로직 실패------")
            }
        }
    }
    func getGoogleIDToken() {
        DLog("Tapped google Button")
        guard let presentVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentVC) { signInResult, error in
            
            guard let result = signInResult else {
                   DLog("❌ 로그인 결과 없음")
                   return
               }
            
            let user = result.user
            let idToken = user.idToken?.tokenString ?? "ID Token 없음"
            Task {
                await self.postSocialLogin(provider: .google, code: idToken)
            }
        }
    }
    
    func postSocialLogin(
        provider: LoginButtonProvider,
        code: String
    ) async {
        do {
            let request = SocialLoginRequest(platform: "ios", code: code)
            let response = try await authUsecase.postSocialLogin(
                provider: provider,
                request: request
            )
            // TODO: 소셜로그인 response를 받아서 어떻게 처리할 것인지 layer 나누고 처리해야함
            // TODO: UserName, id, accessToken, refreshToken -  UserDefaults에 저장
        } catch {
            DLog("socialLogin Error - \(error.localizedDescription)")
        }
    }
    
    func refreshAccessToken() async {
        do {
            // TODO: UserDefaults에서 refresh 가져와서 넣기
            let response = try await authUsecase.postRefreshToken(refreshToken: "")
        } catch {
            DLog("refresh access Toekn errer - \(error.localizedDescription)")
        }
    }
    
    func logout() async {
        do {
            // TODO: UserDefaults에서 accessToken 가져와서 넣기
            let response = try await authUsecase.postLogout(accessToken: "")
        } catch {
            DLog("logout fail - \(error.localizedDescription)")
        }
    }
}

extension MainLoginViewModel {

    func googleLogin() -> String {
        var idToken = ""
        guard let presentVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return "" }
        GIDSignIn.sharedInstance.signIn(withPresenting: presentVC) { signInResult, error in
            
            guard let result = signInResult else {
                   DLog("❌ 로그인 결과 없음")
                   return
               }

               let user = result.user
               let name = user.profile?.name ?? "이름 없음"
               let email = user.profile?.email ?? "이메일 없음"
               idToken = user.idToken?.tokenString ?? "ID Token 없음"
            
            DLog("✅ 로그인 성공")
            DLog("이름: \(name)")
            DLog("이메일: \(email)")
            DLog("ID Token: \(idToken)")
            
        }
        
        return idToken
    }
    
    func postSocialLogin(
        provider: String,
        code: String
    ) {
        
        let url = baseUrl + "/api/oauth/\(provider)/callback"
        
        let parameters: Parameters = [
            "platform": "ios",
            "code": "\(code)"
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseDecodable(of: LoginResponse.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    
    func refreshToken(refreshToken: String) {
        let url = baseUrl + "/api/tokens/refresh"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(refreshToken)"
        ]
        
        
        AF.request(
            url,
            method: .post,
            headers: headers
        )
        .responseDecodable (of: RefreshResponse.self) { response in
            DLog(response)
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    
    func tappedLogout(accessToken: String) {
        let url = baseUrl + "/api/users/logout"

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(accessToken)"
        ]
        
        
        AF.request(
            url,
            method: .post,
            headers: headers
        )
        .responseDecodable (of: BaseResponse.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    
//    func emailSignup() {
//        let url = baseUrl + "/api/users/signup"
//        
//        let parameter: Parameters = [
//            "email": "slpm3957@naver.com",
//            "password": "IosTest1234!",
//            "termsAndConditions": true
//        ]
//        
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json"
//        ]
//        
//        AF.request(
//            url,
//            method: .post,
//            parameters: parameter,
//            encoding: JSONEncoding.default,
//            headers: headers
//        )
//        .responseDecodable(of: LoginResponse.self) { response in
//            switch response.result {
//            case .success(let value):
//                print("✅ 성공: \(value)")
//            case .failure(let error):
//                print("❌ 실패: \(error)")
//            }
//        }
//    }
    
//    func emailLogin() {
//        let url = baseUrl + "/api/users/login"
//        
//        let parameter: Parameters = [
//            "email": "slpm3957@naver.com",
//            "password": "newIosPassword1!"
//        ]
//        
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json"
//        ]
//        
//        AF.request(
//            url,
//            method: .post,
//            parameters: parameter,
//            encoding: JSONEncoding.default,
//            headers: headers
//        )
//        .responseDecodable(of: LoginResponse.self) { response in
//            switch response.result {
//            case .success(let value):
//                print("✅ 성공: \(value)")
//            case .failure(let error):
//                print("❌ 실패: \(error)")
//            }
//        }
//    }
//    
    func findPassword() {
        let url = baseUrl + "/api/auth/email/send"
        
        let parameter: Parameters = [
            "email": "slpm3957@naver.com"
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(
            url,
            method: .post,
            parameters: parameter,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseDecodable(of: BaseResponse.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    
    func vaildateNumber() {
        let url = baseUrl + "/api/auth/email/verify"
        
        let parameter: [String: Any] = [
            "email": "slpm3957@naver.com",
            "code": "a3bb85"
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(
            url,
            method: .post,
            parameters: parameter,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseDecodable(of: BaseResponse.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    

    

    
    func resetPassword() {
        let url = baseUrl + "/api/auth/password/reset"
        
        let parameter: [String: Any] = [
            "email": "slpm3957@naver.com",
            "newPassword": "newIosPassword1!",
            "checkNewPassword" : "newIosPassword1!"
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(
            url,
            method: .patch,
            parameters: parameter,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseDecodable(of: BaseResponse.self) { response in
            switch response.result {
            case .success(let value):
                print("✅ 성공: \(value)")
            case .failure(let error):
                print("❌ 실패: \(error)")
            }
        }
    }
    
    
    
    func tappedLoginButton(provider: LoginButtonProvider) async {
        switch provider {
        case .kakao:
            DLog("Tapped kakao Button")
//            if UserApi.isKakaoTalkLoginAvailable() {
//                UserApi.shared.loginWithKakaoTalk { [self] (oauthToken, error) in
//                    DLog("\(String(describing: oauthToken))")
//                    let code = oauthToken?.accessToken ?? ""
//                    Task {
//                        do {
//                            let request = SocialLoginRequest(platform: "ios", code: code)
//                            loginResponse = try await self.authUsecase.socialLogin(
//                                provider: "KAKAO",
//                                request: request
//                            )
//                            DLog("KAKAO - \(String(describing: loginResponse))")
//                        } catch {
//                            DLog("KAKAO 로그인 실패")
//                        }
//                    }
//                }
//            } else {
//                // 2. 카카오계정 웹 로그인
//                DLog("계정 실패")
//                UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
//                   // handleLogin(oauthToken, error)
//                    DLog("계정 실패실패")
//                }
//            }
        case .google:
            DLog("Tapped google Button")
//            let code = self.googleLogin()
//            Task {
//                do {
//                    let request = SocialLoginRequest(platform: "ios", code: code)
//                    loginResponse = try await self.authUsecase.socialLogin(
//                        provider: "GOOGLE",
//                        request: request
//                    )
//                    DLog("Google - \(String(describing: loginResponse))")
//                } catch {
//                    DLog("KAKAO 로그인 실패")
//                }
//            }
//            
        case .apple:
            DLog("Tapped apple Button")
        }
    }
    
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
               let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                if let data = String(data: appleIDCredential.authorizationCode!, encoding: .utf8) {
                    print("authCode: \(data))")
                }
                print("User ID: \(userIdentifier)")
                print("Full Name: \(String(describing: fullName))")
                print("Email: \(String(describing: email))")
             // TODO: 여기서 email 전의 내용까지만 보내기
                
            }
        case .failure(let error):
            print("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    func handleLogin(_ oauthToken: OAuthToken?, _ error: Error?) {
            if let error = error {
                print("❌ 로그인 실패: \(error.localizedDescription)")
            } else {
                print("✅ 로그인 성공: \(String(describing: oauthToken?.accessToken))")
                // 사용자 정보 가져오기
                UserApi.shared.me { user, error in
                    if let user = user {
                        print("사용자 정보: \(user.kakaoAccount?.email ?? "이메일 없음")")
                    }
                }
            }
        }
    
//    func tappedEmailSignupButton() {
//        self.navigationPath.append(AppRoute.emailSignUp)
//        DLog("이메일 회원가입 버튼 탭")
//    }
    
//    func tappedEmailLoginButton() {
//        self.navigationPath.append(AppRoute.emailLogin)
//        DLog("이메일 로그인 버튼 탭")
//    }
//    
    func tappedProblemLoginButton() {
        DLog("로그인에 문제있음!!!")
    }
}

//enum MainLoginRoute {
//    case emailSignUp
//    case emailLogin
//    case LoginProblem
//}
//
//enum EmailLoginRoute {
//    case emailSignup
//    case findPassword
//    case successLogin
//}
//
//


