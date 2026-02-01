//
//  HomeAPI.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//
import Foundation
import Alamofire

enum HomeAPI: URLRequestConvertible {
    case trending
    case recentReviews
    case upcomingSeason
    case comingSoonAnimes
    case fitAnimeRecommendation
    case animeRecommendation(animeId: Int)
    
    
    var path: String {
        switch self {
        case .trending :
            return "api/home/animes/trending"
        case .recentReviews:
            return "api/home/reviews/recent"
        case .upcomingSeason:
            return "api/animes/upcoming-season"
        case .comingSoonAnimes:
            return "api/home/animes/coming-soon"
        case .fitAnimeRecommendation:
            return "api/home/recommendation/animes"
        case .animeRecommendation(let animeId):
            return "api/home/recommendation/animes/\(animeId)/recent"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .trending:
            return .get
        case .recentReviews:
            return .get
        case .upcomingSeason:
            return .get
        case .comingSoonAnimes:
            return .get
        case .fitAnimeRecommendation:
            return .get
        case .animeRecommendation:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .trending, .recentReviews, .upcomingSeason, .comingSoonAnimes, .fitAnimeRecommendation, .animeRecommendation:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .trending:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .recentReviews:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .upcomingSeason:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .comingSoonAnimes:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .fitAnimeRecommendation:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .animeRecommendation:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        }
        
        
        for key in header.dictionary.keys {
            if let value = header[key] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
