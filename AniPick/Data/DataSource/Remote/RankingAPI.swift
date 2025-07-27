//
//  RankingAPI.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

import Alamofire
import Foundation

enum RankingAPI: URLRequestConvertible {
    case realtime(genre: String?, lastId: Int?, size: Int?)
    case yearAndSeason(year: Int, season: Int, genre: String, lastId: Int, size: Int)
    case allTime(genre: String, lastId: Int, size: Int)
    
    init(realtime genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
        self = .realtime(genre: genre ?? "", lastId: lastId, size: size ?? 20)
    }
    
    init(year: Int, season: Int, genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
        self = .yearAndSeason(year: year, season: season, genre: genre ?? "", lastId: lastId ?? 0, size: size ?? 20)
    }
    
    init(allTime genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
          self = .allTime(genre: genre ?? "", lastId: lastId ?? 0, size: size ?? 20)
      }
    
    var path: String {
        switch self {
        case .realtime:
            return "api/rankings/real-time"
        case let .yearAndSeason(year, season, genre, lastId, size):
            return "api/rankgins/\(year)/\(season)?genre=\(genre)&lastId=\(lastId)&size=\(size)"
        case let .allTime(genre, lastId, size):
            return "api/rankings/all-time?genre=\(genre)&lastId=\(lastId)&size=\(size)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .realtime:
            return .get
        case .yearAndSeason:
            return .get
        case .allTime:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .realtime(genre, lastId, size):
//            let rawParams: [String: Any?]  = [
//                "genre": genre,
//                "lastId": lastId,
//                "size": size
//           ]
//            return rawParams.compactMapValues { $0 }
            return nil
            
        case .yearAndSeason(let year, let season, let genre, let lastId, let size):
            return nil
        case .allTime(let genre, let lastId, let size):
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .realtime:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .yearAndSeason:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .allTime:
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
