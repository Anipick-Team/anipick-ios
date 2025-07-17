//
//  TokenInterceptor.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI
import Alamofire

final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor()
    
    private var requestsToRetry: [(RetryResult) -> Void] = []
    let excludedPaths = ["/login", "/users", "/auth"]
    // accessToken 붙이기
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        DLog("alamofire - adapt 진입")

        DLog("토큰 재발급 필요")
//        // TODO: accessToken이 필요없는 곳에 대해서는 제외처리 해야함
        var modifiedRequest = urlRequest
        let urlString = modifiedRequest.url!.absoluteString

//        if !modifiedRequest.url!.absoluteString.contains("/login") {
//            modifiedRequest.setValue("Bearer \(UserDefaultsManager.shared.getAccessToken())", forHTTPHeaderField: "Authorization")
//        } else {
//            DLog("포함 안하고 있음")
//            completion(.success(modifiedRequest))
//            return
//        }
        
        // 제외할 경로가 포함되어 있다면 토큰 없이 요청
        if excludedPaths.contains(where: { urlString.contains($0) }) {
            DLog("Authorization 없이 요청: \(urlString)")
            completion(.success(modifiedRequest))
            return
        }

        // 그 외엔 토큰 추가
        let token = UserDefaultsManager.shared.getAccessToken()
        modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        completion(.success(modifiedRequest))
        
        //      self.isRefreshing = false
        DLog("토큰 재발급 성공해서 modifiedRequest 요청")
        completion(.success(modifiedRequest))
        
    }
    
    // 401 오류 감지 및 토큰 갱신
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        
        if let urlError = error as? URLError, urlError.code == .timedOut {
            DLog("⏰ 요청 타임아웃 발생")
            completion(.doNotRetry)
            return
        }
        
        
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            DLog("401 아님 - doNotRetry 보냄")
            completion(.doNotRetry)
            return
        }
        
        requestsToRetry.append(completion)
        
        let refreshToken = UserDefaultsManager.shared.getRefreshToken()
        
        DLog("토큰 갱신 요청 시작")
        
        AuthAPIService.shared.postRefreshToken(refreshToken: refreshToken) { result in
            switch result {
            case .success(let response):
                guard let accessToken = response.result?.token?.accessToken,
                      let refreshToken = response.result?.token?.refreshToken else {
                    self.requestsToRetry.forEach { $0(.doNotRetry) }
                    self.requestsToRetry.removeAll()
                    //      self.isRefreshing = false
                    return
                }
                
                UserDefaultsManager.shared.setAccessToken(accessToken: accessToken)
                UserDefaultsManager.shared.setRefreshToken(refreshToken: refreshToken)
                
                DLog("토큰 갱신 성공 - 대기 중인 요청 재시도")
                self.requestsToRetry.forEach { $0(.retry) }
                
            case .failure(let error):
                DLog("토큰 갱신 실패: \(error)")
                self.requestsToRetry.forEach { $0(.doNotRetry) }
            }
            
            self.requestsToRetry.removeAll()
            //      self.isRefreshing = false
        }
    }
    
}
