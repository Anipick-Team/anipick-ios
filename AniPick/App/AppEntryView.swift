//
//  AppEntryView.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import AuthInterface
import DesignSystem
import DetailInterface
import ExploreInterface
import HomeInterface
import MyInfoInterface
import ReviewInterface
import SwiftUI
import SettingInterface
import Utils

struct AppEntryView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject var viewModel = AppEntryViewModel()
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                if navigationManager.isLoggedIn {
                    AppDIContainer.makeContentView(activeTab: .home)
                } else {
                    AppDIContainer.authBuilder.make(.mainLogin)
                        .onAppear { AnalyticsManager.logScreen("login") }
                }
            }
            .background(Color.white)
            .onChange(of: navigationManager.isLoggedIn) { newValue in
                DLog("🔐 [Login] AppEntryView 루트 전환 - isLoggedIn=\(newValue) → \(newValue ? "홈" : "로그인") 화면")
            }
            // 로그인·로그아웃으로 루트가 바뀔 때도 다시 받는다 (레거시 onAppear와 같음)
            .task {
                async let metaData: Void = viewModel.fetchMetaData()
                async let version: Void = viewModel.checkVersion()
                _ = await (metaData, version)
            }
            // 새 Feature가 push한 Route의 목적지. 탭 루트에서 한 번만 등록한다 (A2)
            .navigationDestination(for: SettingRoute.self) { route in
                AppDIContainer.settingBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: DetailRoute.self) { route in
                AppDIContainer.detailBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: ExploreRoute.self) { route in
                AppDIContainer.exploreBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                AppDIContainer.homeBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                AppDIContainer.authBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: MyInfoRoute.self) { route in
                AppDIContainer.myInfoBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: ReviewRoute.self) { route in
                AppDIContainer.reviewBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .content(let activeTab):
                    AppDIContainer.makeContentView(activeTab: activeTab)
                }
            }
        }
        .background(Color.white)
        .environment(\.protectedImageLoader, AppDIContainer.protectedImageLoader)
        .sheet(item: $navigationManager.presentedRoute) { presented in
            modalDestination(presented.route)
        }
    }
}

extension AppEntryView {
    /// 새 Feature가 present한 Route의 목적지. 처음 모달 Route가 생기는 이관 반복에서 case를 추가한다.
    @ViewBuilder
    private func modalDestination(_ route: AnyHashable) -> some View {
        let _ = assertionFailure("모달 목적지가 등록되지 않은 Route: \(route)")
        EmptyView()
    }
}

