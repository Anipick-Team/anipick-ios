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
    @Published var characterInfoList: [CastPair] = []
    @Published var seriesInfoList: [SeriesAnime] = []
    @Published var recommendAnimeList: [Anime] = []
    @Published var isSpolier: Bool = false
    
    private let navigationManager: NavigationManager
    @Published var animeId: Int
    
    @Published var isActiveLike: Bool = false
    @Published var seriesAnimeInfo: [SeriesAnime] = []
    @Published var recommendationInfo: [Anime] = []
    
    @Published var hasMyReview: Bool = false
    @Published var reviewContent: String = ""
   // @Published var myReviewCount: Double = 0.0
    @Published var averageRating: String = ""
    @Published var reviewCount: Int = 0
    @Published var MyReview: MyReviewItem? = nil
    @Published var myReviewCreatedAt: String = ""
    @Published var selectedAnimationStatusTab: AnimationWatchStatus = .empty
    @Published var storedMyReviewRate: Double = 0.0
    @Published var myLikeCount: Int = 0
    
    
    let session = Session(interceptor: TokenInterceptor.shared)
    
    init(animeId: Int, navigationManager: NavigationManager) {
        self.animeId = animeId
        self.navigationManager = navigationManager
        self.fetchAnimationInfo(animeId: animeId)
        self.fetchSeriesAnimeInfo()
        self.fetchRecommendationAnimeInfo()
        self.fetchReview()
        self.getMyReview()
        self.fetchCharacterAndVoiceActor(animeId: animeId)
        self.fetchSeriesInfo(animeId: animeId)
        self.fetchRecommendAnimeList(animeId: animeId)
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
                    self.averageRating = value.result.averageRating ?? "-"
                    self.reviewCount = value.result.reviewCount ?? 0
                    //    self.reviewContent = value.result.description ?? ""
                    self.isActiveLike = value.result.isLiked ?? false
                    self.selectedAnimationStatusTab = AnimationWatchStatus.fromStatus(value.result.watchStatus ?? "") ?? .empty
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
    
    
    func fetchCharacterAndVoiceActor(animeId: Int) {
        session.request(AnimeAPI.animeDetailActorInfo(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: CastResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("animeDetailActorInfo success - \(value)")
                    self.characterInfoList = value.result
                    
                case .failure(let error):
                    DLog("animeDetailActorInfo error - \(error)")
                }
            }
    }
    
    func fetchSeriesInfo(animeId: Int) {
        session.request(AnimeAPI.animeDetailSeriesInfo(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: SeriesDetailResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch Series Detail fetch Series Detail response - \(value)")
                    self.seriesInfoList = value.result
                case .failure(let error):
                    DLog("fetch Series Detail error - \(error)")
                }
            }
    }
    
    func fetchRecommendAnimeList(animeId: Int) {
        session.request(AnimeAPI.animeDetailRecommendation(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecommendedAnimeResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("fetch recommend Anime success - \(value)")
                    self.recommendAnimeList = value.result
                case .failure(let error):
                    DLog("fetch recommend Anime error - \(error)")
                }
            }
    }
    
    
    func fetchReview() {
        session.request(
            AnimeAPI.reviewList(
                animeId: self.animeId,
                sort: "latest",
                isSpoiler: self.isSpolier,
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
                    if self.isSpolier {
                        self.reviewList = reviewList
                    } else {
                        self.reviewList = reviewList.filter { $0.isSpoiler == false }
                    }
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
                    DLog("getNyReview  - \(value)")
                    if let result = value.result {
                        if let reviewId = result.reviewId {
                            self.hasMyReview = true
                            self.reviewContent = result.content ?? ""
                            self.myReviewCreatedAt = result.createdAt ?? ""
                            self.storedMyReviewRate = result.rating ?? 0
                            self.myLikeCount = result.likeCount ?? 0
                        } else {
                            self.hasMyReview = false
                        }
                    }
                case .failure(let error):
                    DLog("에러 발생 - \(error)")
                }
            }
    }
    
    func registerStarRating(ratedStar: Double) {
        session.request(AnimeAPI.registerRating(animeId: self.animeId, rating: ratedStar))
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
    
    // TODO: ReviewAPI가 아닌 AnimeAPI 써야할,,듯,,?
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
    
    func tappedLikeReviewButton(reviewId: Int) {
        session.request(ReviewAPI.likeReview(id: reviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 좋아요 success - \(value)")
                case .failure(let error):
                    DLog("최근 리뷰 좋아요 failure - \(error)")
                }
            }
    }
    
    func tappedDislikeReviewButton(reviewId: Int) {
        session.request(ReviewAPI.cancelReview(id: reviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 좋아요 취소 success - \(value)")
                case .failure(let error):
                    DLog("최근 리뷰 좋아요 취소 failure - \(error)")
                }
            }
    }
    
    func postAnimeWatchingStatus(animeId: Int, status: String) {
        session.request(AnimeAPI.animeWatchingStatus(animeId: animeId, status: status))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    if value.code == 128 {
                        self.deleteAnimeWatchingStatus(animeId: animeId)
                        self.postAnimeWatchingStatus(animeId: animeId, status: status)
                    }
                    DLog("애니메이션 시청 상태 등록 성공 - \(value)")
                case .failure(let error):
                    DLog("애니메이션 시청 상태 등록 실패 - \(error)")
                }
            }
    }
    
    func deleteAnimeWatchingStatus(animeId: Int) {
        session.request(AnimeAPI.deleteAnimeWatchingStatus(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("애니메이션 시청 상태 삭제 성공 - \(value)")
                case .failure(let error):
                    DLog("애니메이션 시청 상태 삭제 실패 - \(error)")
                }
            }
    }
    
    func postReportReivew(id: Int, message: String) {
        session.request(ReviewAPI.reportReview(id: id, message: message))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("리뷰 신고 성공 - \(value)")
                case .failure(let error):
                    DLog("리뷰 신고 실패 - \(error)")
                }
            }
    }
    
    func postBlockUser(userId: Int) {
        session.request(ReviewAPI.blockUser(userId: userId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("작성자 차단 성공 - \(value)")
                case .failure(let error):
                    DLog("작성자 차단 실패 - \(error)")
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
                    DLog("리뷰 삭제 성공 - \(value)")
                case .failure(let error):
                    DLog("리뷰 삭제 실패 - \(error)")
                }
            }
    }
    
    func moveToWriteReview() {
        self.navigationManager.push(route: .review(starRating: self.storedMyReviewRate, animeId: self.animeId))
    }
    
    func setLastVisitedAnimeId() {
        UserDefaultsManager.shared.setLastVisitedAnimeId(animeId: self.animeId)
    }
    
    func moveToRewriteReview(starRating: Double) {
        self.navigationManager.push(route: .review(starRating: starRating, animeId: self.animeId))
    }
    
    func moveToProducerDetailView(studioId: Int) {
        self.navigationManager.push(route: .producerDetail(studioId: studioId))
    }
    
    func moveToVoiceActorDetailView(animeId: Int) {
      //  self.navigationManager.push(route: .voiceActorDetail(animeId: animeId))
        self.navigationManager.push(route: .characterAndVoiceActorDetail(animeId: animeId))
    }
    
    func moveToVoiceActorDetailView(personId: Int) {
        self.navigationManager.push(route: .voiceActorDetail(animeId: personId))
    }
    
    func moveToSeriesDetailView(animeId: Int, animeTitle: String) {
        self.navigationManager.push(route: .seriesDetail(animeId: animeId, animeTitle: animeTitle))
    }
    
    func moveToAnimeDetailView(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
