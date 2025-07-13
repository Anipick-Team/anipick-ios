//
//  ExploreAPIService.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import Alamofire

final class ExploreAPIService {
    static let shared = ExploreAPIService()
    
    private func requestAPI<T: Decodable>(_ api: ExploreAPI) async throws -> T {
        return try await NetworkManager.request(
            path: api.path,
            method: api.method,
            parameters: api.parameters,
            headers: api.header
        )
    }
}

extension ExploreAPIService {
    func getExploreList(category: ExploreSortCategory) async throws -> ExploreResponse {
        try await requestAPI(.exploreAnime(sort: category))
    }
    
    
    
}
