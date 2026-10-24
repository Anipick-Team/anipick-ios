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
    private var isLoading = false
    private var isLoadingMore = false
    private var hasMore = true
    /// 새로고침할 때마다 올린다. 이전 세대의 load more 응답이 새 목록에 붙지 않게 한다.
    private var generation = 0
    private var pendingLikeReviewIds = Set<Int>()
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.fetchRecentReview()
    }
}


extension RecentReviewViewModel {
    
    func fetchRecentReview() {
        self.generation += 1
        let generation = self.generation
        self.lastId = nil
        self.hasMore = true
        self.isLoading = true
        self.isLoadingMore = false
        session.request(ReviewAPI.recentReview(lastId: nil))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
                guard let self, self.generation == generation else { return }
                self.isLoading = false
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 뷰 - \(value)")
                    if let result = value.result,
                       let recentList = result.reviews {
                        self.recentReviewList = recentList
                        self.updateCursor(result.cursor?.lastId)
                    }
                case .failure(let error):
                    DLog("최근 리뷰 뷰 - \(error)")
                }
            }
    }

    func fetchLoadMoreRecentReview() {
        guard !isLoading, !isLoadingMore, hasMore else { return }
        guard let lastId else {
            hasMore = false
            return
        }
        let generation = self.generation
        self.isLoadingMore = true
        session.request(ReviewAPI.recentReview(lastId: lastId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: RecentReviewsResponse.self) { [weak self] response in
                guard let self, self.generation == generation else { return }
                self.isLoadingMore = false
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 뷰 - \(value)")
                    if let result = value.result,
                       let recentList = result.reviews {
                        self.recentReviewList += recentList
                        self.updateCursor(result.cursor?.lastId)
                        if recentList.isEmpty { self.hasMore = false }
                    }
                case .failure(let error):
                    DLog("최근 리뷰 뷰 - \(error)")
                }
            }
    }

    /// 커서가 없으면 마지막 페이지로 본다. 그대로 요청하면 `lastId: nil`로 첫 페이지를 다시 받아 붙인다.
    private func updateCursor(_ lastId: Int?) {
        self.lastId = lastId
        if lastId == nil { self.hasMore = false }
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
    
    
    /// 좋아요 상태를 목록에 먼저 반영하고 요청한다. 실패(네트워크 오류·code != 200)하면 이전 상태로 되돌린다.
    /// 셀이 다시 나타나도 목록 값을 그리므로 상태가 유지된다.
    func setLike(reviewId: Int, liked: Bool) {
        guard !pendingLikeReviewIds.contains(reviewId),
              let index = recentReviewList.firstIndex(where: { $0.reviewId == reviewId }),
              (recentReviewList[index].likedByCurrentUser ?? false) != liked else { return }
        let previous = recentReviewList[index]
        let generation = self.generation
        recentReviewList[index].likedByCurrentUser = liked
        recentReviewList[index].likeCount = previous.likeCount.map { max(0, $0 + (liked ? 1 : -1)) }
        pendingLikeReviewIds.insert(reviewId)

        session.request(liked ? ReviewAPI.likeReview(id: reviewId) : ReviewAPI.cancelReview(id: reviewId))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                self.pendingLikeReviewIds.remove(reviewId)
                let succeeded: Bool
                switch response.result {
                case .success(let value):
                    DLog("최근 리뷰 좋아요\(liked ? "" : " 취소") 응답 - \(value)")
                    succeeded = value.code == 200
                case .failure(let error):
                    DLog("최근 리뷰 좋아요\(liked ? "" : " 취소") failure - \(error)")
                    succeeded = false
                }
                // 그사이 새로고침됐다면 새 목록이 서버 상태이므로 되돌리지 않는다.
                guard !succeeded, self.generation == generation,
                      let index = self.recentReviewList.firstIndex(where: { $0.reviewId == reviewId }) else { return }
                self.recentReviewList[index].likedByCurrentUser = previous.likedByCurrentUser
                self.recentReviewList[index].likeCount = previous.likeCount
            }
    }
    
    
    func moveToDetailAnimation(animeId: Int) {
        self.navigationManager.push(route: .animeDetail(animeId: animeId))
    }
}
