//
//  AnimationInfoViewModel.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import Alamofire

@MainActor
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
    @Published var myReviewId: Int = 0
    @Published var myLikeCount: Int = 0
    
    var reviewLastValue: String? = nil
    var reviewLastId: Int? = nil
    @Published var selectedReviewSortOption: SortOption = .latest
    
    
    private let session = NetworkSession.authenticated
    
    init(animeId: Int, navigationManager: NavigationManager) {
        self.animeId = animeId
        self.navigationManager = navigationManager
        self.fetchAnimationInfo(animeId: animeId)
        self.fetchSeriesAnimeInfo()
        self.fetchReview()
        self.getMyReview()
        self.fetchCharacterAndVoiceActor(animeId: animeId)
        self.fetchSeriesInfo(animeId: animeId)
        self.fetchRecommendAnimeList(animeId: animeId)
    }
}


extension AnimationInfoViewModel {
    
    func convertProfileImage(_ url: String?, completion: @escaping (Image?) -> Void) {
        let imageId = self.convertUrltoProfileId(url)
        session.request(MyInfoAPI.getProfile(imageId: imageId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .response { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let data):
                    DLog("profile Image get successfully: \(String(describing: data))")
                    if let data = data, let uiImage = UIImage(data: data) {
                        let swiftUIImage = Image(uiImage: uiImage)
                        completion(swiftUIImage)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    DLog("Failed to get profile image: \(error.localizedDescription)")
                }
            }
    }
    
    func convertUrltoProfileId(_ url: String?) -> Int {
        if let id = url?.components(separatedBy: "/").last {
            return Int(id) ?? 0
        } else {
            return 0
        }
    }
    
    func fetchAnimationInfo(animeId: Int) {
        session.request(AnimeAPI.animeDetailInfo(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: AnimeDetailResponse.self) { [weak self] response in
                guard let self else { return }
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
                    self.isActiveLike = value.result.isLiked ?? false
                    self.selectedAnimationStatusTab = AnimationWatchStatus.fromStatus(value.result.watchStatus ?? "") ?? .empty
                    AnalyticsManager.logAnimeDetailView(animeId: self.animeId, animeTitle: value.result.title)
                case let .failure(error):
                    DLog("Error: \(error)")
                    AnalyticsManager.logError(error, context: "fetchAnimationInfo")
                }
            }
    }
    
    func fetchSeriesAnimeInfo() {
        session.request(AnimeAPI.seriesAnimeList(animeId: self.animeId, lastId: nil, size: 10))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: SeriesAnimeResponse.self) { [weak self] response in
                guard let self else { return }
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
    

    
    
    func fetchCharacterAndVoiceActor(animeId: Int) {
        session.request(AnimeAPI.animeDetailActorInfo(animeId: animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: CastResponse.self) { [weak self] response in
                guard let self else { return }
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
            .responseDecodable(of: SeriesDetailResponse.self) { [weak self] response in
                guard let self else { return }
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
            .responseDecodable(of: RecommendedAnimeResponse.self) { [weak self] response in
                guard let self else { return }
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
        self.reviewLastId = nil
        self.reviewLastValue = nil
        session.request(
            AnimeAPI.reviewList(
                animeId: self.animeId,
                sort: self.selectedReviewSortOption.request,
                isSpoiler: self.isSpolier,
                lastValue: nil,
                lastId: nil,
                size: 10
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
            guard let self else { return }
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
                self.reviewLastId = value.result?.cursor?.lastId
                self.reviewLastValue = value.result?.cursor?.lastValue
            case .failure(let error):
                DLog("에러 발생 - \(error)")
            }
        }
    }

    func loadMoreReview() {
        session.request(
            AnimeAPI.reviewList(
                animeId: self.animeId,
                sort: self.selectedReviewSortOption.request,
                isSpoiler: self.isSpolier,
                lastValue: self.reviewLastValue,
                lastId: self.reviewLastId,
                size: 10
            )
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case .success(let value):
                DLog("리뷰리뷰 최신 리뷰 - \(value)")
                if let result = value.result,
                   let reviewList = result.reviews {
                    if self.isSpolier {
                        self.reviewList += reviewList
                    } else {
                        self.reviewList += reviewList.filter { $0.isSpoiler == false }
                    }
                }
                self.reviewLastId = value.result?.cursor?.lastId
                self.reviewLastValue = value.result?.cursor?.lastValue
            case .failure(let error):
                DLog("에러 발생 - \(error)")
            }
        }
    }
    
    
    func getMyReview() {
        session.request(AnimeAPI.myReview(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: ReviewResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("getMyReview  - \(value)")
                    if let result = value.result {
                        self.hasMyReview = true
                        self.reviewContent = result.content ?? ""
                        self.myReviewCreatedAt = result.createdAt ?? ""
                        self.storedMyReviewRate = result.rating ?? 0
                        self.myLikeCount = result.likeCount ?? 0
                        self.myReviewId = result.reviewId ?? 0
                    }
                case .failure(let error):
                    DLog("에러 발생 - \(error)")
                }
            }
    }

    func editMyReviewStar(reviewId: Int, ratedStar: Double) {
        session.request(AnimeAPI.editRating(
            reviewId: reviewId,
            rating: ratedStar)
        )
        .cURLDescription { description in
            DLog("\(description)")
        }
        .responseDecodable(of: BaseResponse.self) { [weak self] response in
            guard self != nil else { return }
            switch response.result {
            case .success(let value):
                DLog("별점 수정 완 - \(value)")
            case .failure:
                DLog("별점 수정 에러")
            }
        }
    }
    
    func registerStarRating(ratedStar: Double, completion: (() -> Void)? = nil) {
        session.request(AnimeAPI.registerRating(animeId: self.animeId, rating: ratedStar))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("평점 등록 성공 - \(value)")
                    completion?()
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("좋아요 성공 - \(value)")
                    self.isActiveLike.toggle()
                    AnalyticsManager.logAnimeLike(animeId: self.animeId, animeTitle: self.animeDetailInfo?.title)
                case .failure(let error):
                    DLog("좋아요 실패 - \(error)")
                }
            }
    }

    // TODO: ReviewAPI가 아닌 AnimeAPI 써야할,,듯,,?
    func tappedAnimeDislike() {
        session.request(AnimeAPI.cancelLikeAnime(animeId: self.animeId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("좋아요 성공 - \(value)")
                    self.isActiveLike.toggle()
                    AnalyticsManager.logAnimeUnlike(animeId: self.animeId, animeTitle: self.animeDetailInfo?.title)
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
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
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("애니메이션 시청 상태 삭제 성공 - \(value)")
                case .failure(let error):
                    DLog("애니메이션 시청 상태 삭제 실패 - \(error)")
                }
            }
    }

    func postReportReivew(id: Int, message: String, completion: @escaping () -> Void) {
        session.request(ReviewAPI.reportReview(id: id, message: message))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("리뷰 신고 성공 - \(value)")
                    completion()
                case .failure(let error):
                    DLog("리뷰 신고 실패 - \(error)")
                }
            }
    }

    func postBlockUser(userId: Int, completion: @escaping () -> Void) {
        session.request(ReviewAPI.blockUser(userId: userId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("작성자 차단 성공 - \(value)")
                    completion()
                case .failure(let error):
                    DLog("작성자 차단 실패 - \(error)")
                }
            }
    }

    func deleteMyReview(reviewId: Int, completion: @escaping () -> Void) {
        session.request(ReviewAPI.deleteReview(id: self.myReviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("리뷰 삭제 성공 - \(value)")
                    completion()
                case .failure(let error):
                    DLog("리뷰 삭제 실패 - \(error)")
                }
            }
    }
    
    func moveToWriteReview() {
        self.navigationManager.push(route: .review(starRating: self.storedMyReviewRate, animeId: self.animeId, reviewContent: ""))
    }
    
    func setLastVisitedAnimeId() {
        UserDefaultsManager.shared.setLastVisitedAnimeId(animeId: self.animeId)
    }
    
    func moveToRewriteReview() {
        self.navigationManager.push(route: .review(starRating: self.storedMyReviewRate, animeId: self.animeId, reviewContent: self.reviewContent))
    }
//    
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
    
    func moveToRecommendView(animeId: Int, animeTitle: String) {
        self.navigationManager.push(route: .recommend(animeId: animeId, animeTitle: animeTitle))
    }


    /// 공유할 아이템 목록 반환
    /// - 앱 설치 O: anipick://anime/{id} 딥링크로 바로 이동
    /// - 앱 설치 X: 앱스토어 URL로 이동
    func makeShareItems() -> [Any] {
        guard let detail = animeDetailInfo else { return [] }
        let title = detail.title ?? "애니픽"
        let animeId = detail.animeId

        AnalyticsManager.logAnimeShare(animeId: animeId, animeTitle: title)

        let universalLink = URL(string: "https://anipick.p-e.kr/app/anime/detail/\(animeId)")!
        let shareText = "애니픽에서 '\(title)'을 확인해보세요!"

        return [shareText, universalLink]
    }
}
