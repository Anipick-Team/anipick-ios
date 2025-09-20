//
//  ReviewAPIService.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

final class ReviewAPIService {
    static let shared = ReviewAPIService()
    
    private func requestAPI<T: Decodable>(_ api: ReviewAPI) async throws -> T {
        return try await NetworkManager.request(
            path: api.path,
            method: api.method,
            parameters: api.parameters,
            headers: api.headers
        )
    }
}

extension ReviewAPIService {
    
    /// 최근 리뷰 목록 가져오기
    func getRecentReviews() async throws -> RecentReviewsResponse {
        try await requestAPI(.recentReview)
    }
    
    /// 리뷰 좋아요
    func likeReview(id: Int) async throws -> BaseResponse {
        try await requestAPI(.likeReview(id: id))
    }
    
    /// 리뷰 좋아요 취소
    func cancelReview(id: Int) async throws -> BaseResponse {
        try await requestAPI(.cancelReview(id: id))
    }
    
    /// 리뷰 삭제
    func deleteReview(id: Int) async throws -> BaseResponse {
        try await requestAPI(.deleteReview(id: id))
    }
    
    /// 리뷰 신고
//    func reportReview(id: Int) async throws -> BaseResponse {
//        try await requestAPI(.reportReview(id: id))
//    }
    
    /// 유저 차단
    func blockUser(userId: Int) async throws -> BaseResponse {
        try await requestAPI(.blockUser(userId: userId))
    }
}

