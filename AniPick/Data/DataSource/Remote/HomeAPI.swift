//
//  HomeAPI.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

import Alamofire

enum HomeAPI {
    case trending
    case recentReviews
    case upcomingSeason
    case comingSoonAnimes
    
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
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .trending, .recentReviews, .upcomingSeason, .comingSoonAnimes:
            return nil
        }
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
