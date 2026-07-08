//
//  ProducerDetailViewModel.swift
//  AniPick
//
//  Created by cho on 9/3/25.
//

import SwiftUI
import Alamofire

@MainActor
final class ProducerDetailViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    private let studioId: Int
    
    private let session = NetworkSession.authenticated
    
    @Published var producerName: String = ""
    @Published var producerList: [(String, [AnimeWithSeasonYear])] = []
    
    private var productCount: Int = 0
    private var lastId: Int? = nil
    private var lastValue: String? = nil
    init(navigationManager: NavigationManager, studioId: Int) {
        self.navigationManager = navigationManager
        self.studioId = studioId
    }
}

extension ProducerDetailViewModel {
    func fetchProducerInfo() {
        session.request(
            AnimeAPI.studioDetailInfo(
                studioId: self.studioId,
                lastId: self.lastId,
                lastValue: self.lastValue,
                size: 20
            )
        )
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: StudioDetailResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case let .success(value):
                    DLog("studio Detail test - \(response)")
                    self.producerName = value.result.studioName
                    self.producerList = self.makeGroupProducerList(
                        existing: self.producerList,
                        incoming: value.result.animes
                    )
                    self.lastId = value.result.cursor.lastId
                    self.lastValue = value.result.cursor.lastValue
                case let .failure(error):
                    DLog("producer Detail Info error - \(error)")
                }
                
            }
    }
    
    func loadMoreIfNeeded(animeId: Int) {
        if self.lastId == animeId {
            self.fetchProducerInfo()
        }
    }
    
    private func makeGroupProducerList(
        existing: [(String, [AnimeWithSeasonYear])],
        incoming produceInfoList: [AnimeWithSeasonYear]
    ) -> [(String, [AnimeWithSeasonYear])] {

        var dict: [String: [AnimeWithSeasonYear]] =
            Dictionary(uniqueKeysWithValues: existing.map { ($0.0, $0.1) })

        var seen = Set<Int>()
        for (_, arr) in dict {
            self.productCount += arr.count
            for a in arr {
                if let id = a.animeId { seen.insert(id) }
            }
        }

        let groupedIncoming = Dictionary(grouping: produceInfoList, by: { $0.seasonYear })
        for (year, arr) in groupedIncoming {
            var bucket = dict[year] ?? []
            for a in arr {
                if let id = a.animeId {
                    if !seen.contains(id) {
                        bucket.append(a)
                        seen.insert(id)
                    }
                } else {
                    bucket.append(a)
                }
            }
            dict[year] = bucket
        }

        let result = dict
            .map { ($0.key, $0.value) }
            .sorted { (lhs, rhs) in (Int(lhs.0) ?? 0) > (Int(rhs.0) ?? 0) }

        return result
    }

    func moveToDetailAnimeView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
