//
//  Untitled.swift
//  AniPick
//
//  Created by cho on 6/1/25.
//

import UIKit
import AnalyticsLive

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // TODO: 보안처리 필요
        AnalyticsLive.configure()
        AnalyticsManager.restoreUser()
        // 소셜 SDK는 AuthClient만 안다 (이관 Q5)
        AppDIContainer.liveAuthClient.configureSDKs()
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return AppDIContainer.liveAuthClient.handleOpenURL(url)
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
