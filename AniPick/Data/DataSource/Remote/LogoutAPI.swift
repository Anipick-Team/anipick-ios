//
//  LogoutAPI.swift
//  AniPick
//
//  Created by cho on 7/30/25.
//
import Foundation
import Alamofire

enum LogoutAPI: URLRequestConvertible {
    case logout
    
    var path: String {
        switch self {
        case .logout:
            return "api/users/logout"
        }
    }
    
    
    var method: HTTPMethod {
        switch self {
        case .logout:
            return .post
        }
    }
    
    var parameters: Parameters? {
        return nil
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .logout:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        }
        
        for key in header.dictionary.keys {
            if let value = header[key] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
        
    }
    
    
    var header: HTTPHeaders {
        switch self {
        case .logout:
            return [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"
            ]
        }
    }
}
