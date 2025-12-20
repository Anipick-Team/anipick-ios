//
//  VersionAPI.swift
//  AniPick
//
//  Created by cho on 12/20/25.
//

import Foundation
import Alamofire

enum VersionAPI: URLRequestConvertible {
    case checkVersion
    case deeplink
    
    var path: String {
        switch self {
        case .checkVersion:
            return "api/version"
        case .deeplink:
            return "api/deeplink"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .checkVersion:
            return .get
        case .deeplink:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .checkVersion:
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

            return [
                "userAppVersion": appVersion,
                "platform": "IOS"
            ]
        case .deeplink:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .checkVersion:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .deeplink:
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
