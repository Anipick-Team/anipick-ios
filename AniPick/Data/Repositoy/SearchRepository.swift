//
//  SearchRepository.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

protocol SearchRepositoryProtocol {
    func getSearchResult(lastId: Int?) async throws -> SearchInitResponse
    func getAnimeQueryResult(query: String, lastId: Int?) async throws -> SearchAnimeQueryResponse
    func getPersonQueryResult(query: String, lastId: Int?) async throws -> SearchPersonQueryResponse
    func getStudioQueryResult(query: String, lastId: Int?) async throws -> SearchStudioQueryResponse
}

struct SearchRepository: SearchRepositoryProtocol {
    let apiService: SearchAPIService
    
    init(apiService: SearchAPIService) {
        self.apiService = apiService
    }
}

extension SearchRepository {
    func getSearchResult(lastId: Int? = nil) async throws -> SearchInitResponse {
        try await apiService.getSearchResult(lastId: lastId)
    }
    
    func getAnimeQueryResult(query: String, lastId: Int? = nil) async throws -> SearchAnimeQueryResponse {
        try await apiService.getAnimeQueryResult(query: query, lastId: lastId)
    }
    
    func getPersonQueryResult(query: String, lastId: Int? = nil) async throws -> SearchPersonQueryResponse {
        try await apiService.getPersonQueryResult(query: query, lastId: lastId)
    }
    
    func getStudioQueryResult(query: String, lastId: Int? = nil) async throws -> SearchStudioQueryResponse {
        try await apiService.getStudioQueryResult(query: query, lastId: lastId)
    }
}
