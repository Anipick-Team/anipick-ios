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
    @StateObject private var appState = AppState()
    
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
                .environmentObject(appState)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
                .onAppear {
                    Task {
                        // TODO: authentication 체크하는 로직 필요
                        
                    }
                }
        }
    }
}
