//
//  RecommendationAPI.swift
//  AniPick
//
//  Created by cho on 7/26/25.
//

import Alamofire
import Foundation

enum RecommendationAPI: URLRequestConvertible {
    case recommedation(lastId: Int?, lastValue: String?)
    case recommedationWithAnimeId(animeId: Int, lastId: Int?, lastValue: String?)
    
    var path: String {
        switch self {
        case .recommedation:
            return "api/recommendation/animes/recommendation/animes"
        case let .recommedationWithAnimeId(animeId, _, _):
            return "api/recommendation/animes/\(animeId)/recent"
            
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .recommedation:
            return .get
        case .recommedationWithAnimeId:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .recommedation(lastId, lastValue):
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "lastValue": lastValue
            ]
            return rawParams.compactMapValues { $0 }
        case let .recommedationWithAnimeId(_, lastId, lastValue):
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "lastValue": lastValue
            ]
            return rawParams.compactMapValues { $0 }
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .recommedation:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .recommedationWithAnimeId:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        }
        
        for key in headers.dictionary.keys {
            if let value = headers[key] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        
        return urlRequest
        
    }
    
    var headers: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
    
}
