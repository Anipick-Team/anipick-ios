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
import KakaoSDKAuth

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
    
    func tappedEmailSignup() {
        navigationManager.push(route: AppRoute.emailSignup)
    }
    
    func tappedEmailLogin() {
        navigationManager.push(route: AppRoute.emailLogin)
    }
    
    func signInWithKakao() async throws -> String {
        // 1) 카카오톡 앱 가능하면 앱으로, 아니면 계정(웹뷰) 로그인
        let oauthToken: OAuthToken
        if UserApi.isKakaoTalkLoginAvailable() {
            oauthToken = try await withCheckedThrowingContinuation { cont in
                UserApi.shared.loginWithKakaoTalk { token, error in
                    if let error { cont.resume(throwing: error) }
                    else if let token { cont.resume(returning: token) }
                    else { cont.resume(throwing: NSError(domain: "Kakao", code: -1)) }
                }
            }
        } else {
            oauthToken = try await withCheckedThrowingContinuation { cont in
                UserApi.shared.loginWithKakaoAccount { token, error in
                    if let error { cont.resume(throwing: error) }
                    else if let token { cont.resume(returning: token) }
                    else { cont.resume(throwing: NSError(domain: "Kakao", code: -1)) }
                }
            }
        }

        // 필요한 건 accessToken
        return oauthToken.accessToken
    }
    
    func kakaoLogin() {
        Task {
            do {
                let accessToken = try await signInWithKakao()
                await self.postSocialLogin(provider: .kakao, code: accessToken)
            } catch {
                DLog("KakaoLogin failed - \(error)")
            }
        }
    }
//    func getKakaoAccessToken() {
//        DLog("Tapped kakao Button")
//        if UserApi.isKakaoTalkLoginAvailable() {
//            UserApi.shared.loginWithKakaoTalk { [self] (oauthToken, error) in
//                DLog("\(String(describing: oauthToken))")
//                let code = oauthToken?.accessToken ?? ""
//                Task {
//                    await self.postSocialLogin(provider: .kakao, code: code)
//                }
//            }
//        } else {
//            // 2. 카카오계정 웹 로그인
//            DLog("Kakao 로그인 값 받아오는 로직 실패-")
//            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
//                handleLogin(oauthToken, error)
//                DLog("Kakao 로그인 값 받아오는 로직 실패----- \(error)")
//            }
//        }
//    }
    
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
            DLog("Social 로그인 확인 - \(provider) - \(code)")
            let request = SocialLoginRequest(platform: "ios", code: code)
            let response = try await authUsecase.postSocialLogin(
                provider: provider,
                request: request
            )
            DLog("Social 로그인 - \(response)")
            if response.code == 200 {
                UserDefaultsManager.shared.setSNSAccount(sns: provider.rawValue)
                UserDefaultsManager.shared.setAccessToken(accessToken: response.result?.token?.accessToken ?? "")
                UserDefaultsManager.shared.setRefreshToken(refreshToken: response.result?.token?.refreshToken ?? "")
                UserDefaultsManager.shared.setNickname(response.result?.nickname ?? "")
                self.navigationManager.push(route: .preferenceSelection)
            }
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
                DLog("✅ 성공: \(value)")
            case .failure(let error):
                DLog("❌ 실패: \(error)")
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

        case .google:
            DLog("Tapped google Button")
            
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
                    DLog("authCode: \(data))")
                }
                DLog("User ID: \(userIdentifier)")
                DLog("Full Name: \(String(describing: fullName))")
                DLog("Email: \(String(describing: email))")
                if let email = appleIDCredential.email {
                    let usernamePart = email.components(separatedBy: "@").first ?? ""
                    DLog("Username part: \(usernamePart)")
                    self.postSocialLogin(provider: "APPLE", code: usernamePart)
                }
          //      self.navigationManager.push(route: .content(activeTab: .home))
            }
        case .failure(let error):
            DLog("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    func tappedProblemLoginButton() {
        DLog("로그인에 문제있음!!!")
    }
}
