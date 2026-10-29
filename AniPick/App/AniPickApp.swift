//
//  AniPickApp.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI
import KakaoSDKAuth
import DesignSystem
import Utils

@main
struct AniPickApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject private var appState = AppState()
    
    init() {
        // NavigationManager가 로그인 여부를 판단하기 위해 토큰을 읽기 전에 실행해야 한다.
        UserDefaultsManager.shared.prepareTokenStorage()
        // 토큰 만료·로그아웃·탈퇴 시 로그인 화면으로 돌아가는 경로는 여기 하나다.
        Task {
            await AppDIContainer.sessionState.observe(AppSession.shared.events)
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white   // 원하는 컬러
        
        // 아이콘/텍스트 색까지 명시하고 싶다면 (옵션)
        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = .gray6
        item.selected.iconColor = .anipickPrimary
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "Gray6Color", in: .designSystem, compatibleWith: nil) ?? .lightGray]
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "AnipickPrimaryColor", in: .designSystem, compatibleWith: nil) ?? .lightGray]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(AppDIContainer.navigationManager)
                // .environmentObject(appState)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                    self.handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    self.handleDeepLink(url)
                }
        }
    }
    
    func handleDeepLink(_ url: URL) {
        DLog("handleDeepLink 수신 - scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil"), path: \(url.path), components: \(url.pathComponents)")
        AppDIContainer.appState.deepLink = DeepLink(url: url)
    }
}
