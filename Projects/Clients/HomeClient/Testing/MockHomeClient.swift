import ClientCore
import HomeClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복)
public final class MockHomeClient: HomeClient {
    public enum Request: Hashable, Sendable {
        case recommendations(lastId: Int?, lastValue: String?)
        case recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
    }

    private struct State {
        var recommendations: [Result<RecommendationPage?, TransportError>] = []
        var requests: [Request] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let delay: Duration

    public init(delay: Duration = .zero) {
        self.delay = delay
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    /// 두 추천 요청이 함께 쓰는 결과
    public func stubRecommendations(_ pages: [Result<RecommendationPage?, TransportError>]) {
        state.withLock { $0.recommendations = pages }
    }

    public func recommendations(lastId: Int?, lastValue: String?) async throws(TransportError)
        -> RecommendationPage?
    {
        return try await recommend(.recommendations(lastId: lastId, lastValue: lastValue))
    }

    public func recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        async throws(TransportError) -> RecommendationPage?
    {
        return try await recommend(
            .recentRecommendations(animeId: animeId, lastId: lastId, lastValue: lastValue))
    }

    private func recommend(_ request: Request) async throws(TransportError) -> RecommendationPage? {
        let result = state.withLock { state -> Result<RecommendationPage?, TransportError> in
            state.requests.append(request)
            guard let first = state.recommendations.first else {
                return .success(nil)
            }
            if state.recommendations.count > 1 {
                state.recommendations.removeFirst()
            }
            return first
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

extension HomeAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> HomeAnime {
        return HomeAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil)
    }
}
