//
//  RankingViewModel.swift
//  AniPick
//
//  Created by cho on 7/15/25.
//

import SwiftUI
import Alamofire

final class RankingViewModel: ObservableObject {
    
    @Published var rankingAnimeList: [RankedAnime] = []
    @Published var selectedGenre: String = "장르"
    @Published var selectedYear: String = ""
    @Published var selectedSeason: String = ""
    
    @Published var isLoadingPage: Bool = false
    @Published var reachedEnd: Bool = false
    
    @Published var isSelectedFilter: RankingFilter = .realTime
    
    var lastId: Int? = nil
    var lastValue: String? = nil
    var lastRank: Int? = nil
  // private var lastId: Int? = nil
    private var seenIds = Set<Int>()
    private let pageSize: Int = 20
    private let genre: Int? = nil
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
       // self.fetchRankingDataList()
    }
    let session = Session(interceptor: TokenInterceptor.shared)
    
    
}

extension RankingViewModel {
    func resetData() {
        if self.isSelectedFilter == .realTime {
            self.fetchNextPage()
        } else if self.isSelectedFilter == .history {
            self.fetchAllTimeList()
        } else if self.isSelectedFilter == .yearQuater {
            self.fetchYearSeasonList()
        }
    }
    
    func fetchFirstPage() {
        self.lastId = nil
        self.lastRank = nil
        self.lastValue = nil
        self.reachedEnd = false
        self.isLoadingPage = false
        seenIds.removeAll()
        rankingAnimeList.removeAll()
        self.resetData()
    }
    
    private func selectedGenreToInt(name: String) -> Int? {
        let genreList = UserDefaultsManager.shared.getMetaDataForGenres()
        if let actionId = genreList.first(where: { $0.name == name })?.id {
            DLog("\(name) 장르의 id 값")
            return actionId
        } else {
            return nil
        }
        
    }
    
    private func fetchYearSeasonList() {
        // TODO: 현재 최신 분기로 잡히도록 만들어야함
        let year = self.selectedYear.isEmpty ? 2025 : Int(self.selectedYear)
        let season = self.selectedSeason.isEmpty || self.selectedSeason == "전체 분기" ? nil : Int(self.selectedSeason)
        let genre = self.selectedGenre == "장르" ? nil : self.selectedGenre
        session.request(
            RankingAPI.yearAndSeason(
                year: year ?? 2025,
                season: season,
                genre: genre,
                lastId: self.lastId,
                lastRank: self.lastRank,
                size: 20
            )
        )
        .cURLDescription { DLog("\($0)") }
        .responseDecodable(of: RankingRealTimeResponse.self) { [weak self] response in
            guard let self else { return }
            self.isLoadingPage = false
            
            switch response.result {
            case .success(let value):
                let incoming = value.result.animes
                self.rankingAnimeList.append(contentsOf: incoming)
                // TODO: lastId를 넣었는데도 rank 1 이 나옴
                // 일단 무한 스크롤 대기
                self.lastId = value.result.cursor.lastId
                self.lastRank = self.rankingAnimeList.last?.rank
                
            case .failure(let error):
                DLog("랭킹 error - \(error)")
            }
        }
    }
    
    private func fetchAllTimeList() {
        session.request(
            RankingAPI.allTime(
                genre: self.selectedGenre == "장르" ? nil : self.selectedGenre,
                lastId: self.lastId,
                lastRank: self.lastRank,
                size: 20
            )
        )
        .cURLDescription { DLog("\($0)") }
        .responseDecodable(of: RankingRealTimeResponse.self) { [weak self] response in
            guard let self else { return }
            self.isLoadingPage = false
            
            switch response.result {
            case .success(let value):
                let incoming = value.result.animes
                self.rankingAnimeList.append(contentsOf: incoming)
                // TODO: lastId를 넣었는데도 rank 1 이 나옴
                // 일단 무한 스크롤 대기
                self.lastId = value.result.cursor.lastId
                self.lastRank = self.rankingAnimeList.last?.rank
                
            case .failure(let error):
                DLog("랭킹 error - \(error)")
            }
        }
    }
    
    func loadMoreIfNeeded(currentItem: RankedAnime) {
        guard !isLoadingPage, !reachedEnd else { return }
        // 마지막 아이템이 보이면 다음 페이지 로드
        if currentItem.animeId == rankingAnimeList.last?.animeId {
            switch self.isSelectedFilter {
            case .realTime:
                self.fetchNextPage()
            case .yearQuater:
                self.fetchYearSeasonList()
            case .history:
                self.fetchAllTimeList()
            }
          
        }
    }

    
    private func fetchNextPage() {
        guard !isLoadingPage, !reachedEnd else { return }
        isLoadingPage = true
        var genreId: Int? = nil
        if self.selectedGenre != "장르" {
            genreId = self.selectedGenreToInt(name: self.selectedGenre)
        }
        session.request(
                RankingAPI.realtime(
                    genre: self.selectedGenre == "장르" ? nil : self.selectedGenre,
                    lastId: self.lastId,
                    lastValue: self.lastValue,
                    size: 20
                )
            )
            .cURLDescription { DLog("\($0)") }
            .responseDecodable(of: RankingRealTimeResponse.self) { [weak self] response in
                guard let self else { return }
                self.isLoadingPage = false

                switch response.result {
                case .success(let value):
                    let incoming = value.result.animes
                    self.rankingAnimeList.append(contentsOf: incoming)
                    // TODO: lastId를 넣었는데도 rank 1 이 나옴
                    // 일단 무한 스크롤 대기
                    self.lastId = value.result.cursor.lastId
                    self.lastValue = value.result.cursor.lastValue

                case .failure(let error):
                    DLog("랭킹 error - \(error)")
                }
            }
    }
    
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
 
    func moveToSearchView() {
        self.navigationManager.push(route: AppRoute.homeSearch)
    }
}
