//
//  HomeSearchViewModel.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

import SwiftUI
import Alamofire

@MainActor
final class HomeSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var initAnimeList: [Anime] = []
    @Published var animeListWithQuery: [AnimeWithClickLog] = []
    @Published var personListWithQuery: [Person] = []
    @Published var studioListWithQuery: [Studio] = []
    @Published var recentKeywordList: [String] = []
    @Published var isShowRecentKeyword: Bool = false
    @Published var selectedTab: SearchTab = .initSearch
    @Published var animeListCount: Int = 0
    @Published var personListCount: Int = 0
    @Published var studioListCount: Int = 0
    @Published var homeSearchResult: HomeSearchResult? = nil
    
    @Published var initLastId: Int? = nil
    @Published var animeLastId: Int? = nil
    @Published var personLastId: Int? = nil
    @Published var studioLastId: Int? = nil

    
    private let usecase: SearchUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(usecase: SearchUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.usecase = usecase
        self.navigationManager = navigationManager
    }
    
    func getInitSearchList() async {
        do {
            let response = try await usecase.getSearchResult(lastId: initLastId)
            if let result = response.result {
                self.initAnimeList = result.popularAnimes
                DLog("home searchView - \(result)")
            } else {
                self.initAnimeList = []
            }
        } catch {
            DLog("searchView에서 init anime data error - \(error.localizedDescription)")
        }
    }
    
    func fetchAnimeSearchList() async {
        do {
            let response = try await usecase.getAnimeQueryResult(query: self.searchText, lastId: animeLastId)
            if let result = response.result {
                DLog("home searchView anime with query- \(result)")
                let newAnimes = result.animes ?? []
                self.animeListWithQuery += newAnimes
                self.animeListCount = result.count ?? 0
                self.animeLastId = result.cursor?.lastId ?? nil
                if animeLastId == nil {
                    AnalyticsManager.logSearch(query: self.searchText)
                }
                sendLogs(for: newAnimes)
            } else {
                self.initAnimeList = []
            }
        } catch {
            AnalyticsManager.logError(error, context: "fetchAnimeSearchList")
        }
    }

    private func sendLogs(for animes: [AnimeWithClickLog]) {
        for anime in animes {
            if let clickLog = anime.clickLog {
                AF.request(clickLog).response { _ in }
            }
            if let impressionLog = anime.impressionLogs {
                AF.request(impressionLog).response { _ in }
            }
        }
    }
    
    func fetchPersonSearchList() async {
        do {
            let response = try await usecase.getPersonQueryResult(query: self.searchText, lastId: personLastId)
            if let result = response.result {
                DLog("home searchview personwith query- \(result)")
                self.personListWithQuery += result.persons ?? []
                self.personListCount = result.count ?? 0
                self.personLastId = result.cursor?.lastId ?? nil
            }
        } catch {
            DLog("fetchPersonSearchList error - \(error.localizedDescription)")
        }
    }
    
    func fetchStudioSearchList() async {
        do {
            let response = try await usecase.getStudioQueryResult(query: self.searchText, lastId: studioLastId)
            if let result = response.result {
                DLog("home searchview studio query- \(result)")
                self.studioListWithQuery += result.studios ?? []
                self.studioListCount = result.count ?? 0
                self.studioLastId = result.cursor?.lastId ?? nil
            }
        } catch {
            DLog("fetchStudioSearchList error - \(error.localizedDescription)")
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
    
    func clearAllList() {
        self.animeListWithQuery.removeAll()
        self.personListWithQuery.removeAll()
        self.studioListWithQuery.removeAll()
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
    
    func moveToProducerDetailView(producerId: Int) {
        self.navigationManager.push(route: .producerDetail(studioId: producerId))
    }
    
    func moveToPersonDetailView(personId: Int) {
        self.navigationManager.push(route: .voiceActorDetail(animeId: personId))
    }
 
}
