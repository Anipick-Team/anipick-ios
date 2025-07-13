//
//  SettingAPI.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//
import Alamofire

enum SettingAPI {
    case editNickname(nickname: String)
    
    var path: String {
        switch self {
        case .editNickname:
            return "api/setting/nickname"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .editNickname:
            return .patch
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .editNickname(let nickname):
            return [
                "nickname": nickname
            ]
        }
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
