//
//  SearchUsecase.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

protocol SearchUsecaseProtocol {
    func getSearchResult() async throws -> SearchInitResponse
    func getAnimeQueryResult(query: String) async throws -> SearchAnimeQueryResponse
    func getPersonQueryResult(query: String) async throws -> SearchPersonQueryResponse
    func getStudioQueryResult(query: String) async throws -> SearchStudioQueryResponse
}

struct SearchUsecase: SearchUsecaseProtocol {
    let searchRepository: SearchRepositoryProtocol
    
    init(searchRepository: SearchRepositoryProtocol) {
        self.searchRepository = searchRepository
    }
}

extension SearchUsecase {
    func getSearchResult() async throws -> SearchInitResponse {
        try await searchRepository.getSearchResult()
    }
    
    func getAnimeQueryResult(query: String) async throws -> SearchAnimeQueryResponse {
        try await searchRepository.getAnimeQueryResult(query: query)
    }
    
    func getPersonQueryResult(query: String) async throws -> SearchPersonQueryResponse {
        try await searchRepository.getPersonQueryResult(query: query)
    }
    
    func getStudioQueryResult(query: String) async throws -> SearchStudioQueryResponse {
        try await searchRepository.getStudioQueryResult(query: query)
    }
}
