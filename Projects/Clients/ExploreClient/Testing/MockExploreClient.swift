import ClientCore
import ExploreClientInterface
import os

/// 요청을 기록하고 정해 둔 페이지를 돌려준다.
public final class MockExploreClient: ExploreClient {
    public struct Request: Equatable, Sendable {
        public let query: String?
        public let year: Int?
        public let season: Int?
        public let genreId: Int?
        public let lastId: Int?

        public init(query: String?, year: Int?, season: Int?, genreId: Int?, lastId: Int?) {
            self.query = query
            self.year = year
            self.season = season
            self.genreId = genreId
            self.lastId = lastId
        }
    }

    private let state:
        OSAllocatedUnfairLock<(page: Result<OnboardingPage?, TransportError>, requests: [Request])>

    public init(_ page: Result<OnboardingPage?, TransportError> = .success(nil)) {
        state = OSAllocatedUnfairLock(initialState: (page, []))
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func onboardingAnimes(
        query: String?,
        year: Int?,
        season: Int?,
        genreId: Int?,
        lastId: Int?
    ) async throws(TransportError) -> OnboardingPage? {
        return try state.withLock {
            $0.requests.append(
                Request(query: query, year: year, season: season, genreId: genreId, lastId: lastId))
            return $0.page
        }
        .get()
    }
}

extension OnboardingAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> OnboardingAnime {
        return OnboardingAnime(
            animeId: id, title: "애니 \(id)", coverImageUrl: nil, genres: ["액션", "SF"])
    }
}
