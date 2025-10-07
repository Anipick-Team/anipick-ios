//
//  ExploreAPI.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import Alamofire
import Foundation

enum ExploreSortCategory: String, CaseIterable {
    case popularity
    case rating 
    
    var title: String {
        switch self {
        case .popularity:
            return "인기순"
        case .rating:
            return "평점순"
        }
    }
}

struct ExploreReqeustItem: Codable {
    let year: Int?
    let season: Int?
    let genres: [Int]? // id 값으로 구분
    let type: String? // TV, OVA, MOVIE
    let lastId: Int? //다음 페이지시 추가됨
    let size: Int? // 기본 18
    let genreOp: String? // AND, OR -> OR, AND 조건
    let lastValue: Int? //마지막 값 - 평점순 조회 + 다음페이지 시 추가
}

enum ExploreAPI: URLRequestConvertible {
    case exploreAnime(sort: ExploreSortCategory, item: ExploreReqeustItem?)
    
    var path: String {
        switch self {
        case .exploreAnime:
            return "api/explore/animes"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .exploreAnime:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .exploreAnime(sort, item):
            guard let item = item else {
                return nil
            }

            let rawParams: [String: Any?] = [
                "sort": sort,
                "year": item.year,
                "season": item.season,
                "genres": item.genres,
                "type": item.type,
                "lastId": item.lastId,
                "size": item.size ?? 18, // ✅ 기본값 처리
                "genreOp": item.genreOp,
                "lastValue": item.lastValue
            ]
            
            DLog("parameter 확욘 - \(rawParams)")

            return rawParams.compactMapValues { $0 }
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .exploreAnime:
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
