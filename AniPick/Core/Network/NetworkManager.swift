
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

    /// URLRequestConvertible 기반 요청이 필요한 화면(API별 인코딩/헤더 처리)에서 사용합니다.
    static func request<T: Decodable>(_ convertible: URLRequestConvertible) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            defaultSession.request(convertible)
                .validate()
                .cURLDescription { description in
                    DLog("\(description)")
                }
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

    static func upload<T: Decodable>(
        data: Data,
        path: String,
        fieldName: String,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            defaultSession.upload(
                multipartFormData: { formData in
                    formData.append(data, withName: fieldName, fileName: fileName, mimeType: mimeType)
                },
                to: baseUrl + path,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("이미지 업로드 응답 성공 - path: \(path)")
                    continuation.resume(returning: value)
                case .failure(let error):
                    DLog("이미지 업로드 응답 실패 - path: \(path), error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}


