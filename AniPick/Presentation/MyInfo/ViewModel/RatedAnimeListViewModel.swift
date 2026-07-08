//
//  RatedAnimeListViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

@MainActor
final class RatedAnimeListViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    @Published var animeId: Int = 0
    @Published var isShowOnlyReview: Bool = false
    @Published var isShowSortOptionView: Bool = false
    @Published var sortCategory: RatedSortOption = .latest //정렬 기준 (latest, likes, ratingDesc, ratingAsc)
    @Published var ratedReviewList: [MyReview] = []
    @Published var tmpReviewList: [MyReview] = []
    @Published var lastLikeCount: Int? = nil
    @Published var totalCount: Int? = nil
    @State private var isLoading = false
    private var lastId: Int? = nil
    private var lastRating: Double? = nil
    private let session = NetworkSession.authenticated
}

extension RatedAnimeListViewModel {
  
    func fetchRatedAnimeList() {
        self.clearProperties()
        session.request(
            MyInfoAPI.ratedAnimeList(
                lastId: nil,
                lastLikeCount: nil,
                lastRating: nil,
                sort: self.sortCategory.rawValue,
                reviewOnly: false//self.isShowOnlyReview
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: MyReviewListResponse.self) { response in
            switch response.result {
            case .success(let value):
                self.ratedReviewList = []
                DLog("MyInfo - Rated Review List fetct- \(value)")
                self.tmpReviewList = value.result.reviews ?? []
                self.totalCount = value.result.count
                self.lastId = value.result.cursor?.lastId
                self.lastLikeCount = value.result.reviews?.last?.likeCount
                self.lastRating =  value.result.reviews?.last?.rating
                let existingIds = Set(self.ratedReviewList.map { $0.reviewId })

                var filtered = value.result.reviews?.filter { !existingIds.contains($0.reviewId) }
                
                if self.isShowOnlyReview {
                    filtered = filtered?.filter { $0.reviewContent != nil && !$0.reviewContent!.isEmpty }
                }
                
                self.ratedReviewList = filtered ?? []
                DLog("reviewList 확인 - \(self.ratedReviewList)")

            case .failure(let error):
                DLog("error: \(error)")
            }
        }
    }
    
    func loadMoreAnimeList() {
        guard !isLoading else { return }
        isLoading = true
        session.request(
            MyInfoAPI.ratedAnimeList(
                lastId: self.lastId,
                lastLikeCount: self.lastLikeCount,
                lastRating: self.lastRating,
                sort: self.sortCategory.rawValue,
                reviewOnly: false//self.isShowOnlyReview
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: MyReviewListResponse.self) { response in
            self.isLoading = false
            switch response.result {
            case .success(let value):
                self.tmpReviewList += value.result.reviews ?? []
                let existingIds = Set(self.ratedReviewList.map { $0.reviewId })

                var filtered = value.result.reviews?.filter { !existingIds.contains($0.reviewId) }
                
                if self.isShowOnlyReview {
                    filtered = filtered?.filter { $0.reviewContent != nil && !$0.reviewContent!.isEmpty }
                }
                
                self.ratedReviewList.append(contentsOf: filtered ?? [])
              //  self.ratedReviewList += filtered
                self.lastId = value.result.cursor?.lastId
                self.lastLikeCount = value.result.reviews?.last?.likeCount
                self.lastRating =  value.result.reviews?.last?.rating

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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("success - delete myreview \(value)")
                    self.fetchRatedAnimeList()
                case .failure(let error):
                    DLog("Fail - delete myreview error: \(error)")
                }
            }
    }
    
    func clearProperties() {
        self.lastId = nil
        self.lastLikeCount = nil
        self.lastRating = nil
    }
    
    func moveToAnimeDetail(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
    
    func moveToEditReview(starRating: Double, animeId: Int, reviewContent: String) {
        self.navigationManager.push(route: .review(starRating: starRating, animeId: animeId, reviewContent: reviewContent))
    }
}
