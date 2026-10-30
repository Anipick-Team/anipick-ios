import AuthClientInterface
import Foundation
import GoogleSignIn
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import UIKit

/// 소셜 SDK 호출. App은 SDK를 import하지 않고 이 Client만 부른다 (이관 Q5)
extension LiveAuthClient {
    @MainActor
    public func configureSDKs() {
        KakaoSDK.initSDK(appKey: kakaoAppKey)
    }

    @MainActor
    public func handleOpenURL(_ url: URL) -> Bool {
        if handleKakaoURL(url) {
            return true
        }
        return GIDSignIn.sharedInstance.handle(url)
    }

    @MainActor
    public func handleKakaoURL(_ url: URL) -> Bool {
        guard AuthApi.isKakaoTalkLoginUrl(url) else {
            return false
        }
        return AuthController.handleOpenUrl(url: url)
    }

    /// 레거시 `MainLoginViewModel.signInWithKakao`
    @MainActor
    public func kakaoAccessToken() async throws(SocialSignInFailure) -> String {
        let result: Result<String, NSError> = await withCheckedContinuation { continuation in
            let completion: (OAuthToken?, (any Error)?) -> Void = { token, error in
                if let error {
                    continuation.resume(returning: .failure(error as NSError))
                } else if let token {
                    continuation.resume(returning: .success(token.accessToken))
                } else {
                    continuation.resume(returning: .failure(NSError(domain: "Kakao", code: -1)))
                }
            }
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
        return try result.mapError { SocialSignInFailure.sdk($0) }.get()
    }

    /// 레거시 `MainLoginViewModel.getGoogleIDToken`
    @MainActor
    public func googleIDToken() async throws(SocialSignInFailure) -> String {
        guard let presenting = Self.topMostViewController() else {
            throw .issue("presentingViewController not found")
        }
        let result: Result<String, SocialSignInFailure> = await withCheckedContinuation {
            continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { signInResult, error in
                if let error {
                    continuation.resume(returning: .failure(.sdk(error as NSError)))
                    return
                }
                guard let signInResult else {
                    continuation.resume(returning: .failure(.issue("signInResult nil")))
                    return
                }
                guard let idToken = signInResult.user.idToken?.tokenString, !idToken.isEmpty else {
                    continuation.resume(returning: .failure(.issue("idToken nil or empty")))
                    return
                }
                continuation.resume(returning: .success(idToken))
            }
        }
        return try result.get()
    }

    @MainActor
    private static func topMostViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
