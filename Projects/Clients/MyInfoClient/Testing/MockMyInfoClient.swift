import ClientCore
import MyInfoClientInterface
import os

/// 요청을 기록하고 정해 둔 페이지를 돌려준다 (Store 테스트·Example 앱).
public final class MockMyInfoClient: MyInfoClient {
    public enum Request: Equatable, Sendable {
        case watchList(WatchStatus, lastId: Int?)
        case likedAnimes(lastId: Int?)
        case likedPersons(lastId: Int?)
        case ratedReviews(sort: RatedSort, lastId: Int?, lastLikeCount: Int?, lastRating: Double?)
    }

    public struct Scenario: Sendable {
        public var animePage: Result<MyPage<MyAnime>, TransportError>
        public var personPage: Result<MyPage<MyPerson>, TransportError>
        /// 차례로 돌려준다. 다 쓰면 마지막 것을 반복
        public var ratedPages: [Result<RatedPage, TransportError>]

        public init(
            animePage: Result<MyPage<MyAnime>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil)),
            personPage: Result<MyPage<MyPerson>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil)),
            ratedPages: [Result<RatedPage, TransportError>] = []
        ) {
            self.animePage = animePage
            self.personPage = personPage
            self.ratedPages = ratedPages
        }
    }

    private let state: OSAllocatedUnfairLock<(scenario: Scenario, requests: [Request])>

    public init(_ scenario: Scenario = Scenario()) {
        state = OSAllocatedUnfairLock(initialState: (scenario, []))
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func watchList(
        _ status: WatchStatus,
        lastId: Int?
    ) async throws(TransportError) -> MyPage<MyAnime> {
        return try state.withLock {
            $0.requests.append(.watchList(status, lastId: lastId))
            return $0.scenario.animePage
        }
        .get()
    }

    public func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime> {
        return try state.withLock {
            $0.requests.append(.likedAnimes(lastId: lastId))
            return $0.scenario.animePage
        }
        .get()
    }

    public func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson> {
        return try state.withLock {
            $0.requests.append(.likedPersons(lastId: lastId))
            return $0.scenario.personPage
        }
        .get()
    }
}

extension MockMyInfoClient {
    public func ratedReviews(
        sort: RatedSort,
        lastId: Int?,
        lastLikeCount: Int?,
        lastRating: Double?
    ) async throws(TransportError) -> RatedPage {
        return try state.withLock { state -> Result<RatedPage, TransportError> in
            state.requests.append(
                .ratedReviews(
                    sort: sort, lastId: lastId, lastLikeCount: lastLikeCount, lastRating: lastRating
                ))
            let pages = state.scenario.ratedPages
            guard let first = pages.first else {
                return .success(RatedPage(count: 0, lastId: nil, reviews: []))
            }
            if pages.count > 1 {
                state.scenario.ratedPages.removeFirst()
            }
            return first
        }
        .get()
    }
}

extension RatedReview {
    /// 테스트·Example용
    public static func sample(
        _ id: Int,
        content: String? = "재밌게 봤어요",
        rating: Double = 4.5,
        likes: Int? = 3
    ) -> RatedReview {
        return RatedReview(
            animeId: id * 10, title: "애니 \(id)", coverImageUrl: nil, rating: rating, reviewId: id,
            reviewContent: content, createdAt: "2026.10.\(id)", likeCount: likes)
    }
}

extension MyAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int, rating: Double? = nil) -> MyAnime {
        return MyAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil, myRating: rating)
    }
}

extension MyPerson {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> MyPerson {
        return MyPerson(personId: id, name: "인물 \(id)", profileImageUrl: nil)
    }
}
