//
//  ProfileAPI.swift
//  AniPick
//
//  Created by cho on 8/10/25.
//

import Foundation
import SwiftUI
import Alamofire

enum ProfileAPI: URLRequestConvertible {
    case editProfileImage(image: UIImage)
    
    var path: String {
        switch self {
        case .editProfileImage:
            return "api/mypage/profile-image"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .editProfileImage:
            return .post

        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .editProfileImage:
            return nil

        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case let .editProfileImage(image):
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ProfileAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Image data conversion failed"])
            }
            // multipart/form-data로 파일을 첨부
                    let multipartFormData: MultipartFormData = MultipartFormData()
                    multipartFormData.append(imageData, withName: "profileImageFile", fileName: "profile.jpg", mimeType: "image/jpeg")
                    
                    // 추가 파라미터가 있다면 여기에 포함할 수 있음 (예: user_id)
                    // multipartFormData.append(Data("user_id".utf8), withName: "user_id")
                    // URLRequest에 multipartFormData를 설정
                    urlRequest.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try multipartFormData.encode()
                }
  //      }
        
        for key in headers.dictionary.keys {
            if let value = headers[key] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
    }
    
    var headers: HTTPHeaders {
        return [//"Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
