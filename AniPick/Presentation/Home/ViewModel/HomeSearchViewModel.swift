//
//  HomeSearchViewModel.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

import SwiftUI

@MainActor
final class HomeSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var initAnimeList: [Anime] = []
    @Published var recentKeywordList: [String] = []
    @Published var isShowRecentKeyword: Bool = false
    @Published var selectedTab: SearchTab = .initSearch
    
    private let usecase: SearchUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(usecase: SearchUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
    
    func getInitSearchList() async {
        do {
            let response = try await usecase.getSearchResult()
            if let result = response.result {
                self.initAnimeList = result.popularAnimes
            } else {
                self.initAnimeList = []
            }
        } catch {
            DLog("searchView에서 init anime data error - \(error.localizedDescription)")
        }
    }
    
    func saveRecentKeyword(_ keyword: String) {
        UserDefaultsManager.shared.setHomeRecentKeyword(keyword)
        self.recentKeywordList.insert(keyword, at: 0)
    }
    
    func clearAllRecentKeywordList() {
        UserDefaultsManager.shared.clearHomeRecentKeyword()
        self.recentKeywordList.removeAll()
        self.isShowRecentKeyword = false
    }
    
    func removeSpecificKeyword(_ keyword: String) {
        self.recentKeywordList.removeAll { $0 == keyword }

        UserDefaultsManager.shared.setHomeRecentKeywordList(recentKeywordList)
        self.isShowRecentKeyword = !self.recentKeywordList.isEmpty
    }
    
    func checkRecentKeywordList() {
        let keywords = UserDefaultsManager.shared.getHomeRecentKeyword()
        if keywords.isEmpty {
            self.isShowRecentKeyword = false
        } else {
            self.isShowRecentKeyword = true
            self.recentKeywordList = keywords
        }
    }
    
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    
 
}
