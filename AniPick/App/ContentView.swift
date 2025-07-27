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
    
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        TabView(selection: $viewModel.activeTab) {
            AppDIContainer.makeHomeView()
                .tabItem {
                    Image(viewModel.activeTab == .home ? .homeFilled : .homeUnfilled)
                    Text("홈")
                        
                }
                .foregroundStyle(viewModel.activeTab == .home ? Color.primaryColor: Color.textGrayColor)
                .tag(Tab.home)
            
            AppDIContainer.makeRakingView()
                .tabItem {
                    Image(viewModel.activeTab == .ranking ? .rankingFilled : .rankingUnfilled)
                    Text("랭킹")
                }
                .tag(Tab.ranking)
            
            AppDIContainer.makeExploreView()
                .tabItem {
                    Image(viewModel.activeTab == .research ? .reseachFilled : .researchUnfilled)
                    Text("탐색")
                }
                .tag(Tab.research)
            
            AppDIContainer.makeMyInfoView()
                .tabItem {
                    Image(viewModel.activeTab == .myInfo ? .myInfoFilled : .myInfoUnfilled)
                    Text("마이")
                }
                .tag(Tab.myInfo)
        }
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    AppDIContainer.makeContentView(activeTab: .home)
}
