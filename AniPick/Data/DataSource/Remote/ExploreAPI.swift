//
//  ExploreAPI.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import Alamofire

enum ExploreSortCategory: String {
    case popularity
    case rating
}

enum ExploreAPI {
    case exploreAnime(sort: ExploreSortCategory)
    
    var path: String {
        switch self {
        case let .exploreAnime(sort):
            return "api/explore/animes?sort=\(sort.rawValue)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .exploreAnime:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .exploreAnime:
            return nil
        }
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
