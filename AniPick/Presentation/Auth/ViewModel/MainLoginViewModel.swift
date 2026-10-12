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
final class MainLoginViewModel: ObservableObject {
    
    @Published var moveToEmailSignupView: Bool = false
    
    @Published var isSignedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    
    @Published var isShowWithdrawlUserPopup: Bool = false
    @Published var isShowSNSSignupPopup: Bool = false
    
    var kakaoToken: String = ""
    
    @Published var loginResponse: LoginResponse?
    
    private let authUsecase: AuthUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(authUsecase: AuthUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.authUsecase = authUsecase
        self.navigationManager = navigationManager
    }
    
    private let baseUrl = "https://anipick.p-e.kr"

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
                AnalyticsManager.logError(error, context: "login_kakao")
            }
        }
    }
    
    func getGoogleIDToken() {
        DLog("🔐 [Login][Google] 구글 로그인 버튼 탭")
        // 포그라운드 활성 씬의 키윈도우 기준으로 최상단 VC를 안전하게 획득 (Set.first 비결정성 방지)
        guard let presentVC = Self.topMostViewController() else {
            DLog("❌ [Login][Google] presentingViewController를 찾지 못함 - 로그인 중단")
            AnalyticsManager.logLoginIssue(provider: "google", reason: "presentingViewController not found")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentVC) { [weak self] signInResult, error in
            guard let self else { return }
            if let error {
                DLog("❌ [Login][Google] signIn 오류: \(error.localizedDescription)")
                AnalyticsManager.logError(error, context: "login_google_signIn")
                return
            }
            guard let result = signInResult else {
                DLog("❌ [Login][Google] signInResult 없음 - 로그인 중단")
                AnalyticsManager.logLoginIssue(provider: "google", reason: "signInResult nil")
                return
            }
            guard let idToken = result.user.idToken?.tokenString, !idToken.isEmpty else {
                DLog("❌ [Login][Google] idToken이 nil/빈값 - 서버 전송 중단 (기존엔 문자열이 전송되어 실패)")
                AnalyticsManager.logLoginIssue(provider: "google", reason: "idToken nil or empty")
                return
            }
            DLog("🔐 [Login][Google] idToken 획득 (길이=\(idToken.count)) - 서버 전송")
            Task {
                await self.postSocialLogin(provider: .google, code: idToken)
            }
        }
    }

    /// 포그라운드 활성 씬의 키윈도우에서 최상단(모달 포함) VC를 반환한다.
    private static func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
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
                let accessToken = response.result?.token?.accessToken ?? ""
                UserDefaultsManager.shared.setSNSAccount(sns: provider.rawValue)
                UserDefaultsManager.shared.setAccessToken(accessToken: accessToken)
                UserDefaultsManager.shared.setRefreshToken(refreshToken: response.result?.token?.refreshToken ?? "")
                UserDefaultsManager.shared.setNickname(response.result?.nickname ?? "")
                DLog("🔐 [Login][Social:\(provider.rawValue)] 서버 200, 토큰 저장 완료 (accessToken 길이=\(accessToken.count))")
                if accessToken.isEmpty {
                    DLog("⚠️ [Login][Social:\(provider.rawValue)] 200이지만 accessToken이 비어있음 - 서버 응답 확인 필요")
                    AnalyticsManager.logLoginIssue(provider: provider.rawValue, reason: "200 but empty accessToken")
                }
                AnalyticsManager.logLogin(method: provider.rawValue)
                if response.result?.reviewCompletedYn ?? true {
                    DLog("🔐 [Login][Social:\(provider.rawValue)] 리뷰완료 사용자 → completeLogin (홈)")
                    self.navigationManager.completeLogin()
                } else {
                    DLog("🔐 [Login][Social:\(provider.rawValue)] 신규 사용자 → 취향선택 이동")
                    self.navigationManager.push(route: .preferenceSelection)
                }
            } else if response.code == 132 {
                DLog("🔐 [Login][Social:\(provider.rawValue)] 탈퇴된 계정 (132)")
                self.isShowWithdrawlUserPopup.toggle()
            } else if response.code == 133 {
                DLog("🔐 [Login][Social:\(provider.rawValue)] SNS 재가입 안내 (133)")
                self.isShowSNSSignupPopup.toggle()
            } else {
                DLog("⚠️ [Login][Social:\(provider.rawValue)] 처리되지 않은 응답코드: \(response.code) - 화면 전환 없음")
                AnalyticsManager.logLoginIssue(provider: provider.rawValue, reason: "unhandled response code: \(response.code)")
            }
        } catch {
            DLog("❌ [Login][Social:\(provider.rawValue)] 예외 발생: \(error.localizedDescription)")
            AnalyticsManager.logError(error, context: "login_social_\(provider.rawValue)")
        }
    }
    
}

extension MainLoginViewModel {
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
                DLog("✅ 성공: \(value)")
            case .failure(let error):
                DLog("❌ 실패: \(error)")
            }
        }
    }

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                DLog("❌ [Login][Apple] AppleIDCredential 캐스팅 실패 - 로그인 중단")
                AnalyticsManager.logLoginIssue(provider: "apple", reason: "credential cast failed")
                return
            }

            // 서버에는 Apple identityToken(JWT)을 code로 전송 (서버에서 서명/클레임 검증)
            guard let tokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  !identityToken.isEmpty else {
                DLog("❌ [Login][Apple] identityToken이 비어있음 - 로그인 중단")
                AnalyticsManager.logLoginIssue(provider: "apple", reason: "empty identityToken")
                return
            }

            DLog("🔐 [Login][Apple] identityToken 전송 (길이=\(identityToken.count))")
            Task {
                await self.postSocialLogin(provider: .apple, code: identityToken)
            }
        case .failure(let error):
            DLog("❌ [Login][Apple] Authorization 실패: \(error.localizedDescription)")
            AnalyticsManager.logError(error, context: "login_apple_authorization")
        }
    }

    func tappedProblemLoginButton() {
        DLog("로그인에 문제있음!!!")
        let url = URL(string: "https://forms.gle/SJ7mbQfyfoe2HDLd7")!
        UIApplication.shared.open(url)
    }
}
