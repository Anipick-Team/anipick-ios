//
//  FakeRefresher.swift
//  AniPickTests
//
//  갱신 결과를 정해 두고 호출을 기록하는 가짜. 응답을 늦춰 동시 호출을 재현한다.
//

import ClientCore
import Session

actor FakeRefresher: TokenRefreshing {
    enum Outcome: Sendable {
        case tokens(TokenPair)
        case rejected
        case failure(TransportError)
    }

    private let outcome: Outcome
    private let delay: Duration
    private(set) var callCount = 0

    init(_ outcome: Outcome, delay: Duration = .zero) {
        self.outcome = outcome
        self.delay = delay
    }

    func refresh(refreshToken: String) async throws(TransportError) -> TokenPair? {
        callCount += 1
        try? await Task.sleep(for: delay)
        switch outcome {
        case .tokens(let tokens):
            return tokens
        case .rejected:
            return nil
        case .failure(let error):
            throw error
        }
    }

    /// 갱신 요청이 들어올 때까지 기다린다. 기한 안에 오지 않으면 `false`.
    func waitUntilCalled(timeout: Duration = .seconds(2)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while callCount == 0 {
            guard ContinuousClock.now < deadline else {
                return false
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}
