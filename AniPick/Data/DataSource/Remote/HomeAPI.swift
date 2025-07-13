//
//  HomeAPIService.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

import Alamofire

enum HomeAPIService {
    case trending
    
    var baseUrl: String {
        "https://" // TODO: baseURL 작성
    }
    
    var path: String {
        switch self {
        case .trending :
            return "/api/home/animes/trending"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .trending:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .trending:
            return nil
        }
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json"]
    }
    
    var url: String {
        baseUrl + path
    }
}
