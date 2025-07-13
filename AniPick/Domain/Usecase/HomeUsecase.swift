//
//  HomeUsecase.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//

protocol HomeUsecaseProtocol {
    func getTrendingAnimes() async throws -> TrendingAnimesResponse
    func getRecentReviews() async throws -> RecentReviewInHomeResponse
    func getUpcomingAnimes() async throws -> AnimeSeasonResponse
    func getComingSoonAnimes() async throws -> ComingSoonResponse
}

struct HomeUsecase: HomeUsecaseProtocol {
    let repo: HomeRepositoryProtocol
    
    init(repo: HomeRepositoryProtocol) {
        self.repo = repo
    }
}

extension HomeUsecase {
    func getTrendingAnimes() async throws -> TrendingAnimesResponse {
        try await repo.getTrendingAnimes()
    }
    
    func getRecentReviews() async throws -> RecentReviewInHomeResponse {
        try await repo.getRecentReviews()
    }
    
    func getUpcomingAnimes() async throws -> AnimeSeasonResponse {
        try await repo.getUpcomingAnimes()
    }
    
    func getComingSoonAnimes() async throws -> ComingSoonResponse {
        try await repo.getComingSoonAnimes()
    }
}
