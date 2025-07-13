//
//  TokenManager.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI
import Alamofire

final class TokenManager {
    static let shared = TokenManager()
    
    private init() { }
    
    var accessToken: String? {
        get {
            return UserDefaultsManager.shared.getAccessToken()
        } set {
            UserDefaultsManager.shared.setAccessToken(accessToken: newValue ?? "")
        }
    }
    var refreshToken: String? {
        get {
            return UserDefaultsManager.shared.getRefreshToken()
        } set {
            UserDefaultsManager.shared.setRefreshToken(refreshToken: newValue ?? "")
        }
    }
    
    func save(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.accessToken.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultKey.refreshToken.rawValue)
    }
}

final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor()

    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []

    // accessToken 붙이기
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        DLog("alamofire - adapt 진입")
        
        if isRefreshing {
            DLog("토큰 재발급 필요")
            var modifiedRequest = urlRequest
            modifiedRequest.setValue("Bearer \(UserDefaultsManager.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
            
            self.isRefreshing = false
            DLog("토큰 재발급 성공해서 modifiedRequest 요청")
            completion(.success(modifiedRequest))
        } else {
            DLog("isRefreshing false 임")
            completion(.success(urlRequest))
        }
    }

    // 401 오류 감지 및 토큰 갱신
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) async {
        guard let response = request.task?.response as? HTTPURLResponse,
            response.statusCode == 401
        else {
            DLog("401 에러 실패실패 - doNotRetry 보내기")
            completion(.doNotRetry)
            return
        }

        requestsToRetry.append(completion)
        Task {
            do {
                let refreshToken = UserDefaultsManager.shared.getRefreshToken()
                let response = try await AuthAPIService.shared.postRefreshToken(refreshToken: refreshToken)
                
                UserDefaultsManager.shared.setAccessToken(accessToken: (response.result?.token!.accessToken)!)
                UserDefaultsManager.shared.setRefreshToken(refreshToken: (response.result?.token!.refreshToken)!)
                
                self.requestsToRetry.forEach { $0(.retry) }
                self.requestsToRetry.removeAll()
                
                DLog("리프레시 성공!!! -> \(UserDefaultsManager.shared.getAccessToken())")
            } catch {
                DLog("리프레시 실패: \(error)")
                self.requestsToRetry.forEach { $0(.doNotRetry) }
                self.requestsToRetry.removeAll()
            }
        }
        
    }
}
