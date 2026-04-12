//
//  AniPickApp.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI
import KakaoSDKAuth

@main
struct AniPickApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject private var appState = AppState()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white   // 원하는 컬러
        
        // 아이콘/텍스트 색까지 명시하고 싶다면 (옵션)
        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = .gray6
        item.selected.iconColor = .anipickPrimary
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "Gray6Color") ?? .lightGray]
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "AnipickPrimaryColor") ?? .lightGray]
        
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

        // Universal Link: https://anipick.p-e.kr/app/anime/detail/123
        if url.scheme == "https", url.host == "anipick.p-e.kr" {
            let components = url.pathComponents.filter { $0 != "/" }
            DLog("Universal Link components: \(components)")
            // /app/anime/detail/{id}
            if components.count >= 4,
               components[0] == "app",
               components[1] == "anime",
               components[2] == "detail",
               let id = Int(components[3]) {
                AppDIContainer.appState.deepLink = .anime(id: id)
            } else {
                AppDIContainer.appState.deepLink = .unknown
            }
            return
        }

        // Custom scheme: anipick://anime/123
        let path = url.host ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        if path == "anime", let idStr = components.first, let id = Int(idStr) {
            AppDIContainer.appState.deepLink = .anime(id: id)
        } else if path == "producer", let idStr = components.first, let id = Int(idStr) {
            AppDIContainer.appState.deepLink = .producer(id: id)
        } else {
            AppDIContainer.appState.deepLink = .unknown
        }
    }
}
