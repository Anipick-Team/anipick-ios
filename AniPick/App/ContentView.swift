//
//  ContentView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import DesignSystem
import SwiftUI
import Utils

/// 로그인 후 루트. 탭마다 내비게이션 스택을 따로 둔다 (TB1·TB2)
struct ContentView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: router.tabSelection) {
            tab(.home, title: "홈", filled: .homeFilled, unfilled: .homeUnfilled) {
                // 레거시가 홈 탭에만 준 기본 글자색 (홈이 보일 때는 늘 선택 상태)
                AppDIContainer.homeBuilder.make(.main)
                    .foregroundStyle(Color.primaryColor)
            }
            tab(.ranking, title: "랭킹", filled: .rankingFilled, unfilled: .rankingUnfilled) {
                AppDIContainer.rankingBuilder.make(.main)
            }
            tab(.research, title: "탐색", filled: .reseachFilled, unfilled: .researchUnfilled) {
                AppDIContainer.exploreBuilder.make(.main)
            }
            tab(.myInfo, title: "마이", filled: .myInfoFilled, unfilled: .myInfoUnfilled) {
                AppDIContainer.myInfoBuilder.make(.main)
            }
        }
        .background(Color.white)
    }

    private func tab(
        _ tab: Tab,
        title: String,
        filled: ImageResource,
        unfilled: ImageResource,
        @ViewBuilder root: () -> some View
    ) -> some View {
        return NavigationStack(path: router.pathBinding(for: tab)) {
            root()
                // 탭을 바꿀 때와 상세 화면에서 탭 루트로 돌아올 때 기록한다 (TB8)
                .onAppear { AnalyticsManager.logScreen(tab.screenName) }
                .featureDestinations()
        }
        .tabItem {
            Image(router.selectedTab == tab ? filled : unfilled)
            Text(title)
        }
        .tag(tab)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter(isLoggedIn: true))
}
