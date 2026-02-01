//
//  MetaDataAPI.swift
//  AniPick
//
//  Created by cho on 7/20/25.
//

import Alamofire
import Foundation

enum MetaDataAPI: URLRequestConvertible {
    case metaData
    
    var path: String {
        switch self {
        case .metaData:
            return "api/animes/meta-data-group"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .metaData:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .metaData:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .metaData:
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
        return ["Content-Type": "application/json"]
    }
}
