//
//  ExploreRepository.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

protocol ExploreRepositoryProtocol {
    func getExploreAnimes(category: ExploreSortCategory, item: ExploreReqeustItem?) async throws -> ExploreResponse
}

struct ExploreRepository: ExploreRepositoryProtocol {
    let apiService: ExploreAPIService
    
    init(apiService: ExploreAPIService) {
        self.apiService = apiService
    }
}

extension ExploreRepository {
    func getExploreAnimes(category: ExploreSortCategory, item: ExploreReqeustItem?) async throws -> ExploreResponse {
        try await apiService.getExploreList(category: category, item: item)
    }
}
