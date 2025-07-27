//
//  AnimeRecommendationAPI.swift
//  AniPick
//
//  Created by cho on 7/20/25.
//

import Alamofire
import Foundation

enum AnimeRecommendationAPI: URLRequestConvertible {
    case recommendation
    
    var path: String {
        switch self {
        case .recommendation:
            return "api/home/recommendation/animes"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .recommendation:
            return .get
        }
    }
    
    
    var parameters: Parameters? {
        switch self {
        case .recommendation:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        switch self {
        case .recommendation:
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
