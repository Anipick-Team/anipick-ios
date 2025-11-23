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
    @Published var ratedReviewList: [MyReview] = []
    @Published var lastLikeCount: Int? = nil
    
    var lastId: Int? = nil
    var lastRating: String? = nil
    let session = Session(interceptor: TokenInterceptor.shared)
}

extension RatedAnimeListViewModel {
    func fetchRatedAnimeList() {
        session.request(
            MyInfoAPI.ratedAnimeList(
                lastId: nil,
                lastLikeCount: nil,
                lastRating: nil,
                sort: self.sortCategory.rawValue,
                reviewOnly: false
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: MyReviewListResponse.self) { resposne in
            switch resposne.result {
            case .success(let value):
                self.ratedReviewList = []
                DLog("MyInfo - Rated Review List fetct- \(value)")
                self.lastId = value.result.cursor.lastId
                self.lastLikeCount = value.result.count
                let existingIds = Set(self.ratedReviewList.map { $0.reviewId })

                var filtered = value.result.reviews.filter { !existingIds.contains($0.reviewId) }
                
                if self.isShowOnlyReview {
                    filtered = filtered.filter { $0.reviewContent != nil && !$0.reviewContent!.isEmpty }
                }
                
                self.ratedReviewList = filtered
                
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
                reviewOnly: false
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: MyReviewListResponse.self) { resposne in
            switch resposne.result {
            case .success(let value):
                self.lastId = value.result.cursor.lastId
                self.lastLikeCount = value.result.count
                let existingIds = Set(self.ratedReviewList.map { $0.reviewId })
                var filtered = value.result.reviews.filter { !existingIds.contains($0.reviewId) }
                if self.isShowOnlyReview {
                    filtered = filtered.filter { $0.reviewContent != nil && !$0.reviewContent!.isEmpty }
                }
                self.ratedReviewList += filtered
                DLog("MyInfo - Rated Review List loadmore - \(value)")
            case .failure(let error):
                DLog("error: \(error)")
            }
        }
    }
    
    func deleteMyReview(reviewId: Int) {
        session.request(ReviewAPI.deleteReview(id: reviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("success - delete myreview \(value)")
                    self.fetchRatedAnimeList()
                case .failure(let error):
                    DLog("Fail - delete myreview error: \(error)")
                }
            }
    }
    
    func moveToAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
