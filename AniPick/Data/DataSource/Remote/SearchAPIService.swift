//
//  SearchAPIService.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

import Alamofire

final class SearchAPIService {
    static let shared = SearchAPIService()
    
    private func requestAPI<T: Decodable>(_ api: SearchAPI) async throws -> T {
        return try await NetworkManager.request(
            path: api.path,
            method: api.method,
            parameters: api.parameters,
            headers: api.header
        )
    }
}

extension SearchAPIService {
    func getSearchResult(lastId: Int? = nil) async throws -> SearchInitResponse {
        try await requestAPI(.searchInit(lastId: lastId))
    }
    
    func getAnimeQueryResult(query: String, lastId: Int? = nil) async throws -> SearchAnimeQueryResponse {
        try await requestAPI(.searchAnimeQuery(query: query, lastId: lastId))
    }
    
    func getPersonQueryResult(query: String, lastId: Int? = nil) async throws -> SearchPersonQueryResponse {
        try await requestAPI(.searchPersonQuery(query: query, lastId: lastId))
    }
    
    func getStudioQueryResult(query: String, lastId: Int? = nil) async throws -> SearchStudioQueryResponse {
        try await requestAPI(.searchStudioQuery(query: query, lastId: lastId))
    }
}
