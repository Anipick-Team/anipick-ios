//
//  LogAPI.swift
//  AniPick
//
//  Created by cho on 3/20/26.
//

import Foundation
import Alamofire

enum LogAPI: URLRequestConvertible {
    case getLog(log: String)
    
    var path: String {
        switch self {
        case .getLog(let log):
            return "api/log/\(log)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getLog:
            return .get
        }
    }
    
    var parameters: Parameters? {
        return nil
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        return request
    }
}
