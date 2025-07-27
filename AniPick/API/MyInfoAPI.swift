//
//  MyInfoAPI.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation
import Alamofire

enum MyInfoAPI: URLRequestConvertible {
    case myInfo
    case toWatchAnimeList(status: String, lastId: Int, size: Int)
    case watchingAnimeList(status: String, lastId: Int, size: Int)
    case finishedAnimeList(status: String, lastId: Int, size: Int)
    case ratedAnimeList(lastId: Int, lastLikeCount: Int, lastRating: Int, size: Int, sort: String, reviewOnly: Bool)
    case likedAnimeList(lastId: Int, size: Int)
    case likedPersonList
    
    
    var path: String {
        switch self {
        case .myInfo:
            return "api/mypage"
        case .toWatchAnimeList:
            return "api/mypage/animes/watchlist"
        case .watchingAnimeList:
            return "api/mypage/animes/watching"
        case .finishedAnimeList:
            return "api/mypage/animes/finished"
        case .ratedAnimeList:
            return "api/mypage/animes/rated"
        case .likedAnimeList:
            return "api/mypage/animes/like"
        case .likedPersonList:
            return "api/mypage/persons/like"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .myInfo:
            return .get
        case .toWatchAnimeList:
            return .get
        case .watchingAnimeList:
            return .get
        case .finishedAnimeList:
            return .get
        case .ratedAnimeList:
            return .get
        case .likedAnimeList:
            return .get
        case .likedPersonList:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .myInfo: //MyInfoResponse
            return nil
        case let .toWatchAnimeList(status, lastId, size): //ToWatchResponse
            return [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": size
            ]
        case let .watchingAnimeList(status, lastId, size): //ToWatchResponse
            return [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": size
            ]
        case let .finishedAnimeList(status, lastId, size): //ToWatchResponse
            return [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": size
            ]
        case let .ratedAnimeList(lastId, lastLikeCount, lastRating, size, sort, reviewOnly): //RatedReviewListResponse
            return [
                "lastId": lastId,
                "lastLikeCount": lastLikeCount,
                "lastRating": lastRating,
                "size": size,
                "sort": sort, // latest, likes, ratingDesc, ratingAsc
                "reviewOnly": reviewOnly
            ]
        case let .likedAnimeList(lastId, size): //ToWatchResponse
            return [
                "lastId": lastId,
                "size": size
            ]
        case .likedPersonList: // LikedPersonListResponse
           return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .myInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .toWatchAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .watchingAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .finishedAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .ratedAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .likedAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .likedPersonList:
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
