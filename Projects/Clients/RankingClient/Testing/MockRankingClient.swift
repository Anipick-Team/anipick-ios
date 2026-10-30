import ClientCore
import RankingClientInterface
import os

/// 요청을 기록하고, 정해 둔 페이지를 차례로 돌려준다 (다 쓰면 마지막 결과를 반복).
public final class MockRankingClient: RankingClient {
    public enum Request: Equatable, Sendable {
        case realTime(genre: String?, lastId: Int?, lastValue: String?)
        case yearSeason(year: Int, season: Int?, genre: String?, lastId: Int?, lastRank: Int?)
        case allTime(genre: String?, lastId: Int?, lastRank: Int?)
    }

    private struct State {
        var results: [Result<RankingPage, TransportError>]
        var requests: [Request] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let delay: Duration

    public init(_ results: [Result<RankingPage, TransportError>], delay: Duration = .zero) {
        state = OSAllocatedUnfairLock(initialState: State(results: results))
        self.delay = delay
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func realTime(
        genre: String?,
        lastId: Int?,
        lastValue: String?
    ) async throws(TransportError) -> RankingPage {
        return try await respond(to: .realTime(genre: genre, lastId: lastId, lastValue: lastValue))
    }

    public func yearSeason(
        year: Int,
        season: Int?,
        genre: String?,
        lastId: Int?,
        lastRank: Int?
    ) async throws(TransportError) -> RankingPage {
        return try await respond(
            to: .yearSeason(
                year: year, season: season, genre: genre, lastId: lastId, lastRank: lastRank))
    }

    public func allTime(
        genre: String?,
        lastId: Int?,
        lastRank: Int?
    ) async throws(TransportError) -> RankingPage {
        return try await respond(to: .allTime(genre: genre, lastId: lastId, lastRank: lastRank))
    }

    private func respond(to request: Request) async throws(TransportError) -> RankingPage {
        let result = state.withLock {
            $0.requests.append(request)
            return $0.results.count > 1 ? $0.results.removeFirst() : $0.results.first
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        guard let result else {
            return RankingPage(animes: [], lastId: 0, lastValue: nil)
        }
        return try result.get()
    }
}

extension RankedAnime {
    /// 테스트·Example용 한 줄
    public static func sample(
        id: Int,
        rank: Int,
        trend: String? = nil,
        change: String? = nil,
        genres: [String] = ["액션"]
    ) -> RankedAnime {
        return RankedAnime(
            animeId: id,
            title: "애니 \(id)",
            coverImageUrl: nil,
            rank: rank,
            change: change,
            trend: trend,
            genres: genres
        )
    }
}
