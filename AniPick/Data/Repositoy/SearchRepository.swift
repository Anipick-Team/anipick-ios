//
//  SearchRepository.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

protocol SearchRepositoryProtocol {
    func getSearchResult() async throws -> SearchInitResponse
    func getAnimeQueryResult(query: String) async throws -> SearchAnimeQueryResponse
    func getPersonQueryResult(query: String) async throws -> SearchPersonQueryResponse
    func getStudioQueryResult(query: String) async throws -> SearchStudioQueryResponse
}

struct SearchRepository: SearchRepositoryProtocol {
    let apiService: SearchAPIService
    
    init(apiService: SearchAPIService) {
        self.apiService = apiService
    }
}

extension SearchRepository {
    func getSearchResult() async throws -> SearchInitResponse {
        try await apiService.getSearchResult()
    }
    
    func getAnimeQueryResult(query: String) async throws -> SearchAnimeQueryResponse {
        try await apiService.getAnimeQueryResult(query: query)
    }
    
    func getPersonQueryResult(query: String) async throws -> SearchPersonQueryResponse {
        try await apiService.getPersonQueryResult(query: query)
    }
    
    func getStudioQueryResult(query: String) async throws -> SearchStudioQueryResponse {
        try await apiService.getStudioQueryResult(query: query)
    }
}
