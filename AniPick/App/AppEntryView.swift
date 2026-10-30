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
import SettingInterface
import SwiftUI
import Utils

struct AppEntryView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject var viewModel = AppEntryViewModel()

    var body: some View {
        Group {
            if router.isLoggedIn {
                ContentView()
            } else {
                // 로그인 전 화면은 스택 하나를 따로 쓴다 (TB6)
                NavigationStack(path: $router.authPath) {
                    AppDIContainer.authBuilder.make(.mainLogin)
                        .onAppear { AnalyticsManager.logScreen("login") }
                        .featureDestinations()
                }
            }
        }
        .background(Color.white)
        .onChange(of: router.isLoggedIn) { newValue in
            DLog("🔐 [Login] AppEntryView 루트 전환 - isLoggedIn=\(newValue) → \(newValue ? "홈" : "로그인") 화면")
        }
        // 로그인·로그아웃으로 루트가 바뀔 때도 다시 받는다 (레거시 onAppear와 같음)
        .task(id: router.isLoggedIn) {
            async let metaData: Void = viewModel.fetchMetaData()
            async let version: Void = viewModel.checkVersion()
            _ = await (metaData, version)
        }
        .environment(\.protectedImageLoader, AppDIContainer.protectedImageLoader)
        .sheet(item: $router.presentedRoute) { presented in
            modalDestination(presented.route)
        }
    }
}

extension AppEntryView {
    /// 새 Feature가 present한 Route의 목적지. 처음 모달 Route가 생기면 case를 추가한다.
    @ViewBuilder
    private func modalDestination(_ route: AnyHashable) -> some View {
        let _ = assertionFailure("모달 목적지가 등록되지 않은 Route: \(route)")
        EmptyView()
    }
}

extension View {
    /// Feature Route의 목적지. 스택마다(탭 4개 + 로그인 전) 한 번씩 등록한다 (A2)
    func featureDestinations() -> some View {
        return self
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
    }
}
