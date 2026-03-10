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
        KakaoSDK.initSDK(appKey: "0342f72c46d8653e8a501fe5704a540c")
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        
        return false
        
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        return false
    }
}
