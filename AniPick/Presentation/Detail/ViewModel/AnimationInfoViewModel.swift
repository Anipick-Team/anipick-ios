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
    @Published var animeDetailInfo: AnimeDetail?
    @Published var reviewList: [ReviewItem] = []
    
    private let navigationManager: NavigationManager
    @Published var animeId: Int
    
    @Published var isActiveLike: Bool = false
    @Published var seriesAnimeInfo: [SeriesAnime] = []
    @Published var recommendationInfo: [Anime] = []
    
    @Published var hasMyReview: Bool = false
    @Published var reviewContent: String = "리유부우우우ㅜ웅"
    @Published var myReviewCount: Double = 0.0
    @Published var averageRating: String = ""
    @Published var reviewCount: Int = 0
    @Published var MyReview: MyReviewItem? = nil
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    
    
    
    init(animeId: Int, navigationManager: NavigationManager) {
        self.animeId = animeId
        self.navigationManager = navigationManager
        self.fetchAnimationInfo(animeId: animeId)
        self.fetchSeriesAnimeInfo()
        self.fetchRecommendationAnimeInfo()
        self.fetchReview()
    }
}


extension AnimationInfoViewModel {
    func fetchAnimationInfo(animeId: Int) {
        session.request(AnimeAPI.animeDetailInfo(animeId: self.animeId))
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
                    self.animeDetailInfo = value.result
                    self.hasMyReview = value.result.isLiked ?? false
                    self.averageRating = value.result.averageRating ?? "nil"
                    self.reviewCount = value.result.reviewCount ?? 0
                    self.reviewContent = value.result.description ?? ""
                    self.isActiveLike = value.result.isLiked ?? false
                case let .failure(error):
                    DLog("Error: \(error)")
                }
            }
    }
    
    func fetchSeriesAnimeInfo() {
        session.request(AnimeAPI.seriesAnimeList(animeId: self.animeId, lastId: nil, size: 10))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: SeriesAnimeResponse.self) { response in
                if let data = response.data {
                    let raw = String(data: data, encoding: .utf8) ?? "⚠️ 디코딩 불가"
                    print("📦 원본 응답: \(raw)")
                }

                switch response.result {
                case let .success(value):
                    DLog("anime Recommendation response - \(response)")
                    if let animeList = value.result,
                       let seriesInfo = animeList.animes {
                        self.seriesAnimeInfo = seriesInfo
                    }
                case let .failure(error):
                    DLog("anime Recommendation Error: \(error)")
                }
            }
    }
    
    func fetchRecommendationAnimeInfo() {
        session.request(AnimeAPI.recommendationAnime(animeId: self.animeId, lastId: nil, size: nil))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendationResponse.self) { response in
                if let data = response.data {
                    let raw = String(data: data, encoding: .utf8) ?? "⚠️ 디코딩 불가"
                    print("📦 원본 응답: \(raw)")
                }

                switch response.result {
                case let .success(value):
                    DLog("anime recommendation response - \(response)")
                    if let animeList = value.result,
                       let seriesInfo = animeList.animes {
                        self.recommendationInfo = seriesInfo
                    }
                case let .failure(error):
                    
                    DLog("anime recommendation Error: \(error)")
                }
            }
    }
    
    
    func fetchReview() {
        session.request(
            AnimeAPI.reviewList(
                animeId: self.animeId,
                sort: "latest",
                isSpoiler: true,
                lastValue: nil,
                lastId: nil,
                size: 10
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecentReviewsResponse.self) { response in
            switch response.result {
            case .success(let value):
                DLog("리뷰리뷰 최신 리뷰 - \(value)")
                if let result = value.result,
                   let reviewList = result.reviews {
                    self.reviewList = reviewList
                }
            case .failure(let error):
                DLog("에러 발생 - \(error)")
            }
        }
        
    }
    
    
    func getMyReview() {
        AF.request(AnimeAPI.myReview(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ReviewResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("리뷰리뷰 최신 리뷰 - \(value)")
//                    if let result = value.result,
//                       let reviewList = result.reviews {
//                        self.reviewList = reviewList
//                    }
                case .failure(let error):
                    DLog("에러 발생 - \(error)")
                }
            }
    }
    
    func registerStarRating() {
        session.request(AnimeAPI.registerRating(animeId: self.animeId, rating: self.myReviewCount))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("평점 등록 성공 - \(value)")
                case .failure(let error):
                    DLog("평점 등록 실패 - \(error)")
                }
            }
    }
    
    func tappedAnimeLike() {
        session.request(AnimeAPI.likeAnime(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("좋아요 성공 - \(value)")
                    self.isActiveLike.toggle()
                case .failure(let error):
                    DLog("좋아요 실패 - \(error)")
                }
            }
    }
    
    func tappedAnimeDislike() {
        session.request(ReviewAPI.cancelReview(id: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("좋아요 성공 - \(value)")
                    self.isActiveLike.toggle()
                case .failure(let error):
                    DLog("좋아요 실패 - \(error)")
                }
            }
    }
    
    func moveToWriteReview() {
        self.navigationManager.push(route: .review(starRating: self.myReviewCount, animeId: self.animeId))
    }
    
    func setLastVisitedAnimeId() {
        UserDefaultsManager.shared.setLastVisitedAnimeId(animeId: self.animeId)
    }
    
    
    func moveToRewriteReview(starRating: Double) {
        self.navigationManager.push(route: .review(starRating: starRating, animeId: self.animeId))
    }
}
