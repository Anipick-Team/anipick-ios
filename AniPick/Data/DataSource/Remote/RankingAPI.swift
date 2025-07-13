//
//  RankingAPI.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

import Alamofire

enum RankingAPI {
    case realtime(genre: String, lastId: Int, size: Int)
    case yearAndSeason(year: Int, season: Int, genre: String, lastId: Int, size: Int)
    case allTime(genre: String, lastId: Int, size: Int)
    
    init(realtime genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
        self = .realtime(genre: genre ?? "", lastId: lastId ?? 0, size: size ?? 20)
    }
    
    init(year: Int, season: Int, genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
        self = .yearAndSeason(year: year, season: season, genre: genre ?? "", lastId: lastId ?? 0, size: size ?? 20)
    }
    
    init(allTime genre: String? = nil, lastId: Int? = nil, size: Int? = nil) {
          self = .allTime(genre: genre ?? "", lastId: lastId ?? 0, size: size ?? 20)
      }
    
    var path: String {
        switch self {
        case let .realtime(genre, lastId, size):
            return "api/rankings/real-time?genre=\(genre)&lastId=\(lastId)&size=\(size)"
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
        return nil
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
