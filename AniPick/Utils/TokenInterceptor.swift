//
//  TokenInterceptor.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI
import Alamofire
import Networking

/// Alamofire 요청에 access 토큰을 붙이고, 토큰 만료(code 119) 시 갱신을 `AuthSession`에 맡긴다.
final class TokenInterceptor: RequestInterceptor {
    static let shared = TokenInterceptor(tokens: AppSession.shared)
    let excludedPaths = ["/login", "/users", "/auth", "/oauth"]
    private let tokens: any TokenProviding

    init(tokens: any TokenProviding) {
        self.tokens = tokens
    }

    // accessToken 붙이기
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        // TODO: 1-6 계약 스텁 — 구현 전
        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // TODO: 1-6 계약 스텁 — 구현 전
        completion(.doNotRetry)
    }
}
