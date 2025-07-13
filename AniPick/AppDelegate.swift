//
//  Untitled.swift
//  AniPick
//
//  Created by cho on 6/1/25.
//

import KakaoSDKCommon
import KakaoSDKAuth
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // TODO: 보안처리 필요
        KakaoSDK.initSDK(appKey: "0342f72c46d8653e8a501fe5704a540c")
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return AuthController.handleOpenUrl(url: url)
    }
}
