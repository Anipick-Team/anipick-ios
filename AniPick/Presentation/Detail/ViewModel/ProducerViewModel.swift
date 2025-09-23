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
    
    var lastId: Int? = nil
    var lastValue: String? = nil
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
            .responseDecodable(of: StudioDetailResponse.self) { response in
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
    
    func loadMoreIfNeeded(currentIndex: Int) {
        if currentIndex < producerList.count - 4 {
            self.fetchProducerInfo()
        }
    }
    
    private func makeGroupProducerList(
        existing: [(String, [AnimeWithSeasonYear])],
        incoming produceInfoList: [AnimeWithSeasonYear]
    ) -> [(String, [AnimeWithSeasonYear])] {

        // 1) 기존 [(year, [items])] -> [year: [items]]
        var dict: [String: [AnimeWithSeasonYear]] =
            Dictionary(uniqueKeysWithValues: existing.map { ($0.0, $0.1) })

        // 2) 중복 검사용 Set (기존에 이미 들어간 animeId들로 시드)
        var seen = Set<Int>()
        for (_, arr) in dict {
            for a in arr {
                if let id = a.animeId { seen.insert(id) }
            }
        }

        // 3) 신규를 시즌연도별로 묶어 merge (기존 순서 보존 + 신규는 뒤에 append)
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
                    // animeId가 nil이면 중복 판단 불가하므로 그대로 추가 (원한다면 여기서도 규칙을 정해 처리)
                    bucket.append(a)
                }
            }
            dict[year] = bucket
        }

        // 4) (year, items)로 되돌리고 연도 내림차순 정렬 (숫자 변환 실패시 0)
        let result = dict
            .map { ($0.key, $0.value) }
            .sorted { (lhs, rhs) in (Int(lhs.0) ?? 0) > (Int(rhs.0) ?? 0) }

        return result
    }
//    
//    private func makeGroupProducerList(produceInfoList: [AnimeWithSeasonYear]) -> [(String, [AnimeWithSeasonYear])] {
//        let grouped = Dictionary(grouping: produceInfoList) { $0.seasonYear }
//        let sortedGroups = grouped
//            .sorted { (lhs, rhs) in
//                (Int(lhs.key) ?? 0) > (Int(rhs.key) ?? 0)
//            }
//
//        return sortedGroups
//    }
//    
    func moveToDetailAnimeView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
