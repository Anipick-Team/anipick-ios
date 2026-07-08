//
//  HomeRepository.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

protocol HomeRepositoryProtocol {
    func getTrendingAnimes() async throws -> TrendingAnimesResponse
    func getRecentReviews() async throws -> RecentReviewInHomeResponse
    func getUpcomingAnimes() async throws -> AnimeSeasonResponse
    func getComingSoonAnimes() async throws -> ComingSoonResponse
}

struct HomeRepository: HomeRepositoryProtocol {
    let apiService: HomeAPIService
    
    init(apiService: HomeAPIService) {
        self.apiService = apiService
    }
}

extension HomeRepository {
    func getTrendingAnimes() async throws -> TrendingAnimesResponse {
        try await apiService.getTrendingAnimes()
    }
    
    func getRecentReviews() async throws -> RecentReviewInHomeResponse {
        try await apiService.getRecentReviews()
    }
    
    func getUpcomingAnimes() async throws -> AnimeSeasonResponse {
        try await apiService.getUpcomingAnimes()
    }
    
    func getComingSoonAnimes() async throws -> ComingSoonResponse {
        try await apiService.getComingSoonAnimes()
    }
}
