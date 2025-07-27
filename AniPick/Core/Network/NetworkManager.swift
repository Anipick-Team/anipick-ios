
//  NetworkManager.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

import Foundation
import Alamofire

enum NetworkManager {
    // TODO: BaseUrl 입력 필요
    static let baseUrl: String = "http://anipick.p-e.kr:8080/"
    
    private static let defaultSession: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return Session(configuration: configuration, interceptor: TokenInterceptor.shared)
    }()
    
    private static let plainSession: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return Session(configuration: configuration)
    }()
    
    static func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        headers: HTTPHeaders = []
    ) async throws -> T {
        
        let session: Session = {
            if path.contains("/login") {
                DLog("🔓 login 관련 요청, interceptor 없이 plainSession 사용")
                return plainSession
            } else {
                return defaultSession
            }
        }()
        
        let encoding: ParameterEncoding = {
            switch method {
            case .get: return URLEncoding.default
            default: return JSONEncoding.default
            }
        }()
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseUrl + path,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .cURLDescription { description in
                DLog("\(description)")
            }
//            .responseString { response in
//                if let data = response.data,
//                   let rawJson = String(data: data, encoding: .utf8) {
//                    DLog("📦 Raw Response JSON:\n\(rawJson)")
//                }
//            }
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("response - \(value)")
                    continuation.resume(returning: value)
                case .failure(let error):
                    DLog("fail - \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}



