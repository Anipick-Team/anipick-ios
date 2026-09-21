//
//  RecentReviewViewModel.swift
//  AniPick
//
//  Created by cho on 7/24/25.
//

import SwiftUI
import Alamofire

@MainActor
final class RecentReviewViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    @Published var recentReviewList: [ReviewItem] = []
    private let session = NetworkSession.authenticated
    
    private var lastId: Int? = nil
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.fetchRecentReview()
    }
}


extension RecentReviewViewModel {
    
    func fetchRecentReview() {
        self.lastId = nil
        session.request(ReviewAPI.recentReview(lastId: nil))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 뷰 - \(value)")
                    if let result = value.result,
                       let recentList = result.reviews {
                        self.recentReviewList = recentList
                        self.lastId = result.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("최근 리뷰 뷰 - \(error)")
                }
            }
    }
    
    func fetchLoadMoreRecentReview() {
        session.request(ReviewAPI.recentReview(lastId: self.lastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 뷰 - \(value)")
                    if let result = value.result,
                       let recentList = result.reviews {
                        self.recentReviewList += recentList
                        self.lastId = result.cursor?.lastId
                    }
                case .failure(let error):
                    DLog("최근 리뷰 뷰 - \(error)")
                }
            }
    }
    
    func reportReview(reviewId: Int, message: String, completionHandler: @escaping (Bool) -> Void) {
        session.request(ReviewAPI.reportReview(id: reviewId, message: message))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("리뷰 신고 success - \(value)")
                    completionHandler(true)
                case .failure(let error):
                    DLog("리뷰 신고 failure - \(error)")
                    completionHandler(false)
                }
            }
        
    }
    
    func blockUser(userId: Int, completionHandler: @escaping (Bool) -> Void) {
        session.request(ReviewAPI.blockUser(userId: userId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("사용자 차단 success - \(value)")
                    completionHandler(true)
                case .failure(let error):
                    DLog("사용자 차단 failure - \(error)")
                    completionHandler(false)
                }
            }
    }
    
    func convertProfileImage(_ url: String?, completion: @escaping (Image?) -> Void) {
        let imageId = self.convertUrltoProfileId(url)
        session.request(MyInfoAPI.getProfile(imageId: imageId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .response { [weak self] response in
                guard let self else { return }
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
    
    
    func tappedLikeReviewButton(reviewId: Int) {
        session.request(ReviewAPI.likeReview(id: reviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
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
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 좋아요 취소 success - \(value)")
                case .failure(let error):
                    DLog("최근 리뷰 좋아요 취소 failure - \(error)")
                }
            }
    }
    
    
    func moveToDetailAnimation(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
