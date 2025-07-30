//
//  SearchAPI.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//
import Foundation
import Alamofire

enum SearchAPI: URLRequestConvertible {
    case searchInit(lastId: Int?)
    case searchAnimeQuery(query: String, lastId: Int?)
    case searchPersonQuery(query: String, lastId: Int?)
    case searchStudioQuery(query: String, lastId: Int?)
    
    var path: String {
        switch self {
        case .searchInit:
            return "api/search/init"
        case .searchAnimeQuery:
            return "api/search/animes"
        case let .searchPersonQuery:
            return "api/search/persons"
        case let .searchStudioQuery:
            return "api/search/studios"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .searchInit:
            return .get
        case .searchAnimeQuery:
            return .get
        case .searchPersonQuery:
            return .get
        case .searchStudioQuery:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .searchInit(lastId):
            let rawParams = [
                "lastId": lastId
            ]
            return rawParams.compactMapValues { $0 }
        case let .searchAnimeQuery(query, lastId):
            let rawParams: [String: Any?] = [
                "query": query,
                "lastId": lastId
            ]
            return rawParams.compactMapValues { $0 }
        case let .searchPersonQuery(query, lastId):
            let rawParams: [String: Any?] = [
                "query": query,
                "lastId": lastId
            ]
            return rawParams.compactMapValues { $0 }
        case let .searchStudioQuery(query, lastId):
            let rawParams: [String: Any?] = [
                "query": query,
                "lastId": lastId
            ]
            return rawParams.compactMapValues { $0 }
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .searchInit:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .searchAnimeQuery:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .searchPersonQuery:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .searchStudioQuery:
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
