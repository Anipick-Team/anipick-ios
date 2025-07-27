//
//  SettingAPI.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation
import Alamofire

enum SettingAPI: URLRequestConvertible {
    case editNickname(nickname: String) // response - baseResponse
    case editEmail(email: String, password: String) // response - baseResponse
    case editPassword(currentPassword: String, newPassword: String, confirmNewPassword: String) //response - baseResponse
    
    
    var path: String {
        switch self {
        case .editNickname:
            return "api/setting/nickname"
        case .editEmail:
            return "api/setting/email"
        case .editPassword:
            return "api/setting/password"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .editNickname:
            return .patch
        case .editEmail:
            return .put
        case .editPassword:
            return .patch
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .editNickname(let nickname):
            return [
                "nickname": nickname
            ]
        case let .editEmail(email, password):
            return [
                "newEmail": email,
                "password": password
            ]
            
        case let .editPassword(currentPassword, newPassword, confirmNewPassword):
            return [
                "currentPassword": currentPassword,
                "newPassword": newPassword,
                "confirmNewPassword": confirmNewPassword
            ]
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .editNickname:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .editEmail:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .editPassword:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
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
