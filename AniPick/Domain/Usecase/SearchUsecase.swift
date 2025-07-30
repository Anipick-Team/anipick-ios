//
//  SearchUsecase.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

protocol SearchUsecaseProtocol {
    func getSearchResult(lastId: Int?) async throws -> SearchInitResponse
    func getAnimeQueryResult(query: String, lastId: Int?) async throws -> SearchAnimeQueryResponse
    func getPersonQueryResult(query: String, lastId: Int?) async throws -> SearchPersonQueryResponse
    func getStudioQueryResult(query: String, lastId: Int?) async throws -> SearchStudioQueryResponse
}

struct SearchUsecase: SearchUsecaseProtocol {
    let searchRepository: SearchRepositoryProtocol
    
    init(searchRepository: SearchRepositoryProtocol) {
        self.searchRepository = searchRepository
    }
}

extension SearchUsecase {
    func getSearchResult(lastId: Int? = nil) async throws -> SearchInitResponse {
        try await searchRepository.getSearchResult(lastId: lastId)
    }
    
    func getAnimeQueryResult(query: String, lastId: Int? = nil) async throws -> SearchAnimeQueryResponse {
        try await searchRepository.getAnimeQueryResult(query: query, lastId: lastId)
    }
    
    func getPersonQueryResult(query: String, lastId: Int? = nil) async throws -> SearchPersonQueryResponse {
        try await searchRepository.getPersonQueryResult(query: query, lastId: lastId)
    }
    
    func getStudioQueryResult(query: String, lastId: Int? = nil) async throws -> SearchStudioQueryResponse {
        try await searchRepository.getStudioQueryResult(query: query, lastId: lastId)
    }
}
