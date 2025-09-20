//
//  ProducerDetailViewModel.swift
//  AniPick
//
//  Created by cho on 9/3/25.
//

import SwiftUI
import Alamofire

final class ProducerDetailViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let studioId: Int
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    @Published var producerName: String = ""
    @Published var producerList: [(String, [AnimeWithSeasonYear])] = []
    
    init(navigationManager: NavigationManager, studioId: Int) {
        self.navigationManager = navigationManager
        self.studioId = studioId
    }
}

extension ProducerDetailViewModel {
    func fetchProducerInfo() {
        session.request(AnimeAPI.studioDetailInfo(studioId: self.studioId, lastId: nil, lastValue: nil, size: 20))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: StudioDetailResponse.self) { response in
                switch response.result {
                case let .success(value):
                    DLog("studio Detail test - \(response)")
                    self.producerName = value.result.studioName
                    self.producerList = self.makeGroupProducerList(produceInfoList: value.result.animes)
                case let .failure(error):
                    DLog("producer Detail Info error - \(error)")
                }
                
            }
    }
    
    private func makeGroupProducerList(produceInfoList: [AnimeWithSeasonYear]) -> [(String, [AnimeWithSeasonYear])] {
        let grouped = Dictionary(grouping: produceInfoList) { $0.seasonYear }
        let sortedGroups = grouped
            .sorted { (lhs, rhs) in
                (Int(lhs.key) ?? 0) > (Int(rhs.key) ?? 0)
            }

        return sortedGroups
    }
    
    func moveToDetailAnimeView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
