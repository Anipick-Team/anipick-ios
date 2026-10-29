//
//  ContentView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI
import Utils

enum Tab: Hashable {
    case home
    case ranking
    case research
    case myInfo
}

struct ContentView: View {
    
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        TabView(selection: $viewModel.activeTab) {
            AppDIContainer.homeBuilder.make(.main)
                .tabItem {
                    Image(viewModel.activeTab == .home ? .homeFilled : .homeUnfilled)
                    Text("홈")
                }
                .foregroundStyle(viewModel.activeTab == .home ? Color.primaryColor: Color.textGrayColor)
                .tag(Tab.home)
            
            AppDIContainer.rankingBuilder.make(.main)
                .tabItem {
                    Image(viewModel.activeTab == .ranking ? .rankingFilled : .rankingUnfilled)
                    Text("랭킹")
                }
                .tag(Tab.ranking)
            
            AppDIContainer.exploreBuilder.make(.main)
                .tabItem {
                    Image(viewModel.activeTab == .research ? .reseachFilled : .researchUnfilled)
                    Text("탐색")
                }
                .tag(Tab.research)
            
            AppDIContainer.myInfoBuilder.make(.main)
                .tabItem {
                    Image(viewModel.activeTab == .myInfo ? .myInfoFilled : .myInfoUnfilled)
                    Text("마이")
                }
                .tag(Tab.myInfo)
        }
        .onAppear {
            DLog("")
            // 상세 화면에서 돌아올 때도 다시 호출되어 현재 탭을 기록한다
            AnalyticsManager.logScreen(viewModel.activeTab.screenName)
        }
        .onChange(of: viewModel.activeTab) { tab in
            AnalyticsManager.logScreen(tab.screenName)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    AppDIContainer.makeContentView(activeTab: .home)
}
