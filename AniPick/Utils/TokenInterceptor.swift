//
//  TokenInterceptor.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI
import Alamofire
import Networking
import os
import Utils

/// Alamofire 요청에 access 토큰을 붙이고, 토큰 만료(code 119) 시 갱신을 `AuthSession`에 맡긴다.
final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor(tokens: AppSession.shared)
    let excludedPaths = ["/login", "/users", "/auth", "/oauth"]
    private let tokens: any TokenProviding
    /// 갱신에 실패해 다시 보내지 않기로 한 요청.
    /// Alamofire는 요청 실패 후 응답 디코딩이 실패하면 같은 요청으로 retry를 한 번 더 부르므로
    /// (Alamofire 5.12 `DataRequest.swift:272-277`) 같은 요청에 갱신을 반복하지 않게 기억한다.
    /// 요청이 해제되면 목록에서도 빠진다.
    private let declinedRequests = OSAllocatedUnfairLock(
        uncheckedState: NSHashTable<Request>.weakObjects()
    )

    init(tokens: any TokenProviding) {
        self.tokens = tokens
    }

    // accessToken 붙이기
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        // 제외할 경로가 포함되어 있다면 토큰 없이 요청
        guard let urlString = urlRequest.url?.absoluteString,
              !excludedPaths.contains(where: { urlString.contains($0) }) else {
            completion(.success(urlRequest))
            return
        }

        // 그 외엔 토큰 추가 (토큰이 없으면 빈 Bearer — 현재 동작 유지)
        Task {
            var modifiedRequest = urlRequest
            let token = await tokens.accessToken() ?? ""
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            completion(.success(modifiedRequest))
        }
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // 재시도는 요청당 1회. 새 토큰으로도 만료면 더 갱신하지 않는다.
        let wasDeclined = declinedRequests.withLockUnchecked { $0.contains(request) }
        guard request.retryCount == 0, !wasDeclined else {
            completion(.doNotRetry)
            return
        }

        // 응답이 없으면(타임아웃 등) 재시도하지 않는다
        guard request.task?.response is HTTPURLResponse,
              let data = (request as? DataRequest)?.data,
              Self.isTokenExpired(data) else {
            completion(.doNotRetry)
            return
        }

        DLog("🚫 code 119 - 토큰 갱신 시도")
        // 동시 갱신 묶기와 실패 시 로그아웃 처리는 AuthSession이 맡는다.
        Task {
            do {
                try await tokens.refreshAccessToken()
                // 기다리는 사이 취소된 요청에 .retry를 돌려주면 Alamofire가 요청을 끝내지 않는다
                // (Alamofire 5.12 `Session.swift:1368`).
                completion(request.isCancelled ? .doNotRetry : .retry)
            } catch {
                DLog("🔐 [Login] 토큰 갱신 실패: \(error)")
                declinedRequests.withLockUnchecked { $0.add(request) }
                completion(.doNotRetry)
            }
        }
    }

    /// 본문 `code == 119`(토큰 만료)인지
    private static func isTokenExpired(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? Int else {
            return false
        }
        return code == 119
    }
}
