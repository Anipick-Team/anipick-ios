//
//  ReviewAPI.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

import Alamofire
import Foundation

enum ReviewAPI: URLRequestConvertible {
    case recentReview
    case likeReview(id: Int)
    case cancelReview(id: Int)
    case deleteReview(id: Int)
    case reportReview(id: Int)
    case blockUser(userId: Int)
    
    var path: String {
        switch self {
        case .recentReview:
            return "api/reviews/recent"
        case let .likeReview(id):
            return "api/reviews/\(id)/like"
        case let .cancelReview(id):
            return "api/reviews/\(id)/like"
        case let .deleteReview(id):
            return "api/reviews/\(id)"
        case let .reportReview(id):
            return "api/reviews/\(id)/report"
        case let .blockUser(userId):
            return "api/\(userId)/block-user"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .recentReview:
            return .get
        case .likeReview:
            return .post
        case .cancelReview:
            return .delete
        case .deleteReview:
            return .delete
        case .reportReview:
            return .post
        case .blockUser:
            return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .recentReview:
            return nil
        case .likeReview(let id):
            return nil
        case .cancelReview(let id):
            return nil
        case .deleteReview(let id):
            return nil
        case .reportReview(let id):
            return ["message": "신고를 왜 했을까요오"]
        case .blockUser(let userId):
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .recentReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .likeReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .cancelReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .deleteReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .reportReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .blockUser:
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
