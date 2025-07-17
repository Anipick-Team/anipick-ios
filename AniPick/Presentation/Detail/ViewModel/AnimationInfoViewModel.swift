//
//  AnimationInfoViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

final class AnimationInfoViewModel: ObservableObject {
    @Published var isShowSortOptionView: Bool = false
    @Published var isShowOnlyReview: Bool = false
    
    private let navigationManager: NavigationManager
    @Published var animeId: Int
    
    init(animeId: Int, navigationManager: NavigationManager) {
        self.animeId = animeId
        self.navigationManager = navigationManager
        self.fetchAnimationInfo(animeId: animeId)
    }
}


extension AnimationInfoViewModel {
    func fetchAnimationInfo(animeId: Int) {
        AF.request(AnimeAPI.animeDetailInfo(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: AnimeDetailResponse.self) { response in
                if let data = response.data {
                    let raw = String(data: data, encoding: .utf8) ?? "⚠️ 디코딩 불가"
                    print("📦 원본 응답: \(raw)")
                }
                
                
                
                switch response.result {
                case let .success(value):
                    DLog("anime Detail - \(response)")
                case let .failure(error):
                    DLog("Error: \(error)")
                }
            }
    }
}
