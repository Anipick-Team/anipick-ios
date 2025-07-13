//
//  ExploreUsecase.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

protocol ExploreUsecaseProtocol {
    func getExploreAnimes(category: ExploreSortCategory) async throws -> ExploreResponse
}

struct ExploreUsecase: ExploreUsecaseProtocol {
    let exploreRepository: ExploreRepositoryProtocol
    
    init(exploreRepository: ExploreRepositoryProtocol) {
        self.exploreRepository = exploreRepository
    }
}

extension ExploreUsecase {
    func getExploreAnimes(category: ExploreSortCategory) async throws -> ExploreResponse {
        try await exploreRepository.getExploreAnimes(category: category)
    }
}
