//
//  RecentReviewViewModel.swift
//  AniPick
//
//  Created by cho on 7/24/25.
//

import SwiftUI
import Alamofire

final class RecentReviewViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    @Published var recentReviewList: [ReviewItem] = []
    let session = Session(interceptor: TokenInterceptor.shared)
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.fetchRecentReview()
    }
}


extension RecentReviewViewModel {
    func fetchRecentReview() {
        session.request(ReviewAPI.recentReview)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecentReviewsResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 뷰 - \(value)")
                    if let result = value.result,
                       let recentList = result.reviews {
                        self.recentReviewList = recentList
                    }
                case .failure(let error):
                    DLog("최근 리뷰 뷰 - \(error)")
                }
            }
    }
    
    func moveToDetailAnimation(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
