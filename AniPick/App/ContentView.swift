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
    
    var body: some View {
        TabView(selection: $selectedTab) {
           // HomeView()
          //  AppleLoginTestView()
            AuthTestView()
         //   MainLoginView()
                .tabItem {
                    Image(selectedTab == .home ? .homeFilled : .homeUnfilled)
                    Text("홈")
                        
                }
                .foregroundStyle(selectedTab == .home ? Color.primaryColor: Color.textGrayColor)
                .tag(Tab.home)
            
            RankingView()
                .tabItem {
                    Image(selectedTab == .ranking ? .rankingFilled : .rankingUnfilled)
                    Text("랭킹")
                }
                .tag(Tab.ranking)
            
            ResearchView()
                .tabItem {
                    Image(selectedTab == .research ? .reseachFilled : .researchUnfilled)
                    Text("탐색")
                }
                .tag(Tab.research)
            
            MyInfoView()
                .tabItem {
                    Image(selectedTab == .myInfo ? .myInfoFilled : .myInfoUnfilled)
                    Text("마이")
                }
                .tag(Tab.myInfo)
            
        }
       // .foregroundStyle(Color.primaryColor)

    }
}

#Preview {
    ContentView()
}
