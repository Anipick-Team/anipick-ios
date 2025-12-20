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
    case toWatchAnimeList(status: String, lastId: Int?)
    case watchingAnimeList(status: String, lastId: Int?)
    case finishedAnimeList(status: String, lastId: Int?)
    case ratedAnimeList(lastId: Int?, lastLikeCount: Int?, lastRating: Double?, sort: String?, reviewOnly: Bool)
    case likedAnimeList(lastId: Int?, size: Int)
    case likedPersonList(lastId: Int?)
    case getProfileImage(imageId: Int)
    case getProfile(imageId: Int)
    
    
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
        case let .getProfileImage(imageId):
            return "api/image/profile-image/\(imageId)"
        case let .getProfile(imageId):
            return "api/image/\(imageId)"
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
        case .getProfileImage:
            return .get
        case .getProfile:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .myInfo: //MyInfoResponse
            return nil
        case let .toWatchAnimeList(status, lastId): //ToWatchResponse
            let rawParams: [String : Any?] = [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": 20
            ]
            
            return rawParams.compactMapValues { $0 }
        case let .watchingAnimeList(status, lastId): //ToWatchResponse
            let rawParams: [String : Any?] = [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": 20
            ]
            
            return rawParams.compactMapValues { $0 }
        case let .finishedAnimeList(status, lastId): //ToWatchResponse
            let rawParams: [String : Any?] = [
                "status": status, // WATCHLIST/WATCHING/FINISHED
                "lastId": lastId,
                "size": 20
            ]
            
            return rawParams.compactMapValues { $0 }
        case let .ratedAnimeList(lastId, lastLikeCount, lastRating, sort, reviewOnly): //RatedReviewListResponse
            let reviewOnlyString = reviewOnly ? "true" : "false"
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "lastLikeCount": lastLikeCount,
                "lastRating": lastRating,
                "size": 20,
                "sort": sort, // latest, likes, ratingDesc, ratingAsc
                "reviewOnly": reviewOnlyString
            ]
            return rawParams.compactMapValues { $0 }
            
        case let .likedAnimeList(lastId, size): //ToWatchResponse
            let rawParams = [
                "lastId": lastId,
                "size": size
            ]
            
            return rawParams.compactMapValues { $0 }
        case let .likedPersonList(lastId):
            let rawParams = [
                "lastId": lastId,
                "size": 30
            ]
            
            return rawParams.compactMapValues { $0 }
        case .getProfileImage:
            return nil
        case .getProfile:
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
        case .getProfileImage:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .getProfile:
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
