//
//  Untitled.swift
//  AniPick
//
//  Created by cho on 6/1/25.
//

import KakaoSDKCommon
import KakaoSDKAuth
import UIKit
import GoogleSignIn
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // TODO: 보안처리 필요
        FirebaseApp.configure()
        AnalyticsManager.restoreUser()
        KakaoSDK.initSDK(appKey: "0342f72c46d8653e8a501fe5704a540c")
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return false
    }

    // Universal Link 콜드 스타트 처리
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }

        let link = DeepLink(url: url)
        if link != .unknown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppDIContainer.appState.deepLink = link
            }
        }
        return true
    }
}
