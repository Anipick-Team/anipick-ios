//
//  SearchAPI.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

import Alamofire

enum SearchAPI {
    case searchInit
    case searchAnimeQuery(query: String)
    case searchPersonQuery(query: String)
    case searchStudioQuery(query: String)
    
    var path: String {
        switch self {
        case .searchInit:
            return "api/search/init"
        case let .searchAnimeQuery(query):
            return "api/search/animes?query=\(query)"
        case let .searchPersonQuery(query):
            return "api/search/persons?query=\(query)"
        case let .searchStudioQuery(query):
            return "api/search/studios?query=\(query)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .searchInit:
            return .get
        case .searchAnimeQuery:
            return .get
        case .searchPersonQuery:
            return .get
        case .searchStudioQuery:
            return .get
        }
    }
    
    var parameters: Parameters? {
        return nil
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
