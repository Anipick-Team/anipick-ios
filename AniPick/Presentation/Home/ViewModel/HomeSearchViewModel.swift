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
    
 
}
