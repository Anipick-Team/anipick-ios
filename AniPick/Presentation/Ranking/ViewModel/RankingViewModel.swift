//
//  RankingViewModel.swift
//  AniPick
//
//  Created by cho on 7/15/25.
//

import SwiftUI
import Alamofire

final class RankingViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    //    self.fetchRankingDataList()
    }
    let session = Session(interceptor: TokenInterceptor.shared)
}

extension RankingViewModel {
    func fetchRankingDataList() {
        session.request(RankingAPI.realtime(genre: nil, lastId: nil, size: nil))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .response { response in
                print("응답 상태 코드: \(response.response?.statusCode ?? 0)")
                if let data = response.data, !data.isEmpty {
                    print("응답 내용: \(String(data: data, encoding: .utf8) ?? "디코딩 실패")")
                } else {
                    print("📭 응답 본문이 없음")
                }
            }
            .responseDecodable(of: RankingRealTimeResponse.self) { response in
                DLog("response - \(response)")
                if let data = response.data,
                   let rawJson = String(data: data, encoding: .utf8) {
                    DLog("📦 Raw Response JSON:\n\(rawJson)")
                }
                switch response.result {
                case .success:
                    DLog("랭킹 성공성공 - \(response)")
                case let .failure(error):
                    DLog("error\(error)")
                }
            }
    }
    
}
