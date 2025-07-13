//
//  AniPickApp.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

@main
struct AniPickApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(AppDIContainer.navigationManager)
                .environmentObject(appState)
                .onAppear {
                    Task {
                        // TODO: authentication 체크하는 로직 필요
                        
                    }
                }
        }
    }
    
    func checkAuthentication() async {
        let accessToken = UserDefaultsManager.shared.getAccessToken()
        
        
        
        
        
    }
}
