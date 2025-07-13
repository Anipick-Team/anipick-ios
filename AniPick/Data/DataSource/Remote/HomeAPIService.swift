//
//  HomeAPIService.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//

import Alamofire

final class HomeAPIService {
    static let shared = HomeAPIService()
    
    private func requestAPI<T: Decodable>(_ api: HomeAPI) async throws -> T {
        return try await NetworkManager.request(
            path: api.path,
            method: api.method,
            parameters: api.parameters,
            headers: api.header
        )
    }
}

extension HomeAPIService {
    func getTrendingAnimes() async throws -> TrendingAnimesResponse {
        try await requestAPI(.trending)
    }
    
    func getRecentReviews() async throws -> RecentReviewInHomeResponse {
        try await requestAPI(.recentReviews)
    }
    
    func getUpcomingAnimes() async throws -> AnimeSeasonResponse {
        try await requestAPI(.upcomingSeason)
    }
    
    func getComingSoonAnimes() async throws -> ComingSoonResponse {
        try await requestAPI(.comingSoonAnimes)
    }
}
