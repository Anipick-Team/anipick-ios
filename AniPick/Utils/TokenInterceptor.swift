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
    private let lock = NSLock()
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []
    let excludedPaths = ["/login", "/users", "/auth"]
    weak var navigationManager: NavigationManager?
    
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
        
        // 제외할 경로가 포함되어 있다면 토큰 없이 요청
        if excludedPaths.contains(where: { urlString.contains($0) }) {
            DLog("Authorization 없이 요청: \(urlString)")
            completion(.success(modifiedRequest))
            return
        }

        // 그 외엔 토큰 추가
        let token = UserDefaultsManager.shared.getAccessToken()
        modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        //      self.isRefreshing = false
        DLog("토큰 재발급 성공해서 modifiedRequest 요청")
        completion(.success(modifiedRequest))
        
    }
    

    
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
        
        guard let response = request.task?.response as? HTTPURLResponse else {
            DLog("응답 없음 - doNotRetry")
            completion(.doNotRetry)
            return
        }
        
        // ✅ 응답 데이터에서 code 파싱
        if let dataRequest = request as? DataRequest,
           let data = dataRequest.data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let code = json["code"] as? Int {
            
            DLog("응답 코드: \(code)")
            
            if code == 119 {
                DLog("🚫 code 119 - 토큰 갱신 시도")

                lock.lock()
                if isRefreshing {
                    requestsToRetry.append(completion)
                    lock.unlock()
                    return
                }
                isRefreshing = true
                lock.unlock()

                let refreshToken = UserDefaultsManager.shared.getRefreshToken()
                AuthAPIService.shared.postRefreshToken(refreshToken: refreshToken) { [weak self] result in
                    guard let self else { return }
                    DLog("postRefreshToken - \(result)")

                    self.lock.lock()
                    self.isRefreshing = false
                    let pending = self.requestsToRetry
                    self.requestsToRetry.removeAll()
                    self.lock.unlock()

                    switch result {
                    case .success(let response):
                        if response.code == 200,
                           let accessToken = response.result?.accessToken,
                           let refreshToken = response.result?.refreshToken {
                            DLog("refreshToken 성공 - accessToken: \(accessToken)")
                            UserDefaultsManager.shared.setAccessToken(accessToken: accessToken)
                            UserDefaultsManager.shared.setRefreshToken(refreshToken: refreshToken)
                            pending.forEach { $0(.retry) }
                            completion(.retry)
                        } else {
                            DLog("refreshToken 실패 - 로그인 화면 이동")
                            pending.forEach { $0(.doNotRetry) }
                            DispatchQueue.main.async {
                                self.navigationManager?.popToRoot()
                                self.navigationManager?.push(route: .mainLoginView)
                            }
                            completion(.doNotRetry)
                        }

                    case .failure(let error):
                        DLog("토큰 갱신 실패: \(error)")
                        pending.forEach { $0(.doNotRetry) }
                        DispatchQueue.main.async {
                            self.navigationManager?.popToRoot()
                            self.navigationManager?.push(route: .mainLoginView)
                        }
                        completion(.doNotRetry)
                    }
                }

                return

            }
        }
        
        completion(.doNotRetry)
    }
}
