
//  NetworkManager.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

import Foundation
import Alamofire

enum NetworkManager {
    // TODO: BaseUrl 입력 필요
    static let baseUrl: String = "https://anipick.p-e.kr/"
    
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
            // 로그인 계열 요청(이메일 로그인 /login, 소셜 로그인 /oauth)은 토큰 인터셉터 없이 요청.
            // 이전 세션의 낡은 accessToken이 Authorization 헤더로 붙어 로그인이 간헐적으로 실패하는 문제 방지.
            if path.contains("/login") || path.contains("/oauth") {
                DLog("🔓 로그인 관련 요청, interceptor 없이 plainSession 사용 - \(path)")
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



