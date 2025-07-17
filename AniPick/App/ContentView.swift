//
//  ContentView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

enum Tab {
    case home
    case ranking
    case research
    case myInfo
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @StateObject var viewModel: ContentViewModel
    var body: some View {
        TabView(selection: $selectedTab) {
            AppDIContainer.makeHomeView()
                .tabItem {
                    Image(selectedTab == .home ? .homeFilled : .homeUnfilled)
                    Text("홈")
                        
                }
                .foregroundStyle(selectedTab == .home ? Color.primaryColor: Color.textGrayColor)
                .tag(Tab.home)
            
            AppDIContainer.makeRakingView()
                .tabItem {
                    Image(selectedTab == .ranking ? .rankingFilled : .rankingUnfilled)
                    Text("랭킹")
                }
                .tag(Tab.ranking)
            
            AppDIContainer.makeExploreView()
                .tabItem {
                    Image(selectedTab == .research ? .reseachFilled : .researchUnfilled)
                    Text("탐색")
                }
                .tag(Tab.research)
            
            AppDIContainer.makeMyInfoView()
                .tabItem {
                    Image(selectedTab == .myInfo ? .myInfoFilled : .myInfoUnfilled)
                    Text("마이")
                }
                .tag(Tab.myInfo)
        }
    }
}

#Preview {
    AppDIContainer.makeContentView()
}
