//
//  RatedAnimeListViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

final class RatedAnimeListViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isShowOnlyReview: Bool = false
    @Published var isShowSortOptionView: Bool = false
    @Published var sortCategory: RatedSortOption = .latest //정렬 기준 (latest, likes, ratingDesc, ratingAsc)
    @Published var ratedReviewList: [ReviewItem] = []
    @Published var lastLikeCount: Int? = nil
    
    var lastId: Int? = nil
    var lastRating: String? = nil
    
    
    
    let session = Session(interceptor: TokenInterceptor.shared)
}

extension RatedAnimeListViewModel {
    func fetchRatedAnimeList() {
        self.ratedReviewList.removeAll()
        session.request(
            MyInfoAPI.ratedAnimeList(
                lastId: nil,
                lastLikeCount: nil,
                lastRating: nil,
                sort: self.sortCategory.rawValue,
                reviewOnly: self.isShowOnlyReview
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecentReviewsResponse.self) { resposne in
            switch resposne.result {
            case .success(let value):
                if let result = value.result,
                   let reviewList = result.reviews {
                    self.lastId = result.cursor?.lastId
                    self.lastLikeCount = result.count
                    self.lastRating = result.cursor?.lastValue
                    let existingIds = Set(self.ratedReviewList.map { $0.reviewId })

                    let filtered = reviewList.filter { !existingIds.contains($0.reviewId) }

                    self.ratedReviewList = filtered
                }
                DLog("MyInfo - Rated Review List fetct- \(value)")
       
            case .failure(let error):
                DLog("error: \(error)")
            }
        }
    }
    
    func loadMoreAnimeList() {
        session.request(
            MyInfoAPI.ratedAnimeList(
                lastId: self.lastId,
                lastLikeCount: self.lastLikeCount,
                lastRating: self.lastRating,
                sort: self.sortCategory.rawValue,
                reviewOnly: self.isShowOnlyReview
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecentReviewsResponse.self) { resposne in
            switch resposne.result {
            case .success(let value):
                if let result = value.result,
                   let reviewList = result.reviews {
                    self.lastId = result.cursor?.lastId
                    self.lastLikeCount = result.count
                    self.lastRating = result.cursor?.lastValue
                    
                    let existingIds = Set(self.ratedReviewList.map { $0.reviewId })

                    let filtered = reviewList.filter { !existingIds.contains($0.reviewId) }

                    self.ratedReviewList += filtered
                }
                DLog("MyInfo - Rated Review List loadmore - \(value)")
       
            case .failure(let error):
                DLog("error: \(error)")
            }
        }
    }
}
