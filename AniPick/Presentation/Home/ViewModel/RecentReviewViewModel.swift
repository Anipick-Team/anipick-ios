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
    
    func reportReview(reviewId: Int, message: String) {
        session.request(ReviewAPI.reportReview(id: reviewId, message: message))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("리뷰 신고 success - \(value)")
                case .failure(let error):
                    DLog("리뷰 신고 failure - \(error)")
                }
            }
        
    }
    
    func blockUser(userId: Int) {
        session.request(ReviewAPI.blockUser(userId: userId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("사용자 차단 success - \(value)")
                case .failure(let error):
                    DLog("사용자 차단 failure - \(error)")
                }
            }
    }
    
    
    func moveToDetailAnimation(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
