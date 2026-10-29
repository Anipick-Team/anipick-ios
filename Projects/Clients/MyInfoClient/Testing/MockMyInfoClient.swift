import ClientCore
import Foundation
import MyInfoClientInterface
import os

/// 요청을 기록하고 정해 둔 페이지를 돌려준다 (Store 테스트·Example 앱).
public final class MockMyInfoClient: MyInfoClient {
    public enum Request: Equatable, Sendable {
        case watchList(WatchStatus, lastId: Int?)
        case likedAnimes(lastId: Int?)
        case likedPersons(lastId: Int?)
        case ratedReviews(sort: RatedSort, lastId: Int?, lastLikeCount: Int?, lastRating: Double?)
        case myPosts(lastId: Int?)
        case myComments(lastId: Int?)
    }

    public struct Scenario: Sendable {
        public var animePage: Result<MyPage<MyAnime>, TransportError>
        public var personPage: Result<MyPage<MyPerson>, TransportError>
        /// 차례로 돌려준다. 다 쓰면 마지막 것을 반복
        public var ratedPages: [Result<RatedPage, TransportError>]
        public var postPage: Result<ContentPage<MyPost>, TransportError>
        public var commentPage: Result<ContentPage<MyComment>, TransportError>
        /// 내 콘텐츠 응답을 늦춘다 (받는 중 상태 시험)
        public var contentDelay: Duration

        public init(
            animePage: Result<MyPage<MyAnime>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil)),
            personPage: Result<MyPage<MyPerson>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil)),
            ratedPages: [Result<RatedPage, TransportError>] = [],
            postPage: Result<ContentPage<MyPost>, TransportError> = .success(
                ContentPage(count: 0, lastId: nil, items: [])),
            commentPage: Result<ContentPage<MyComment>, TransportError> = .success(
                ContentPage(count: 0, lastId: nil, items: [])),
            contentDelay: Duration = .zero
        ) {
            self.animePage = animePage
            self.personPage = personPage
            self.ratedPages = ratedPages
            self.postPage = postPage
            self.commentPage = commentPage
            self.contentDelay = contentDelay
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

extension MockMyInfoClient {
    public func myPosts(lastId: Int?) async throws(TransportError) -> ContentPage<MyPost> {
        let (result, delay) = state.withLock {
            $0.requests.append(.myPosts(lastId: lastId))
            return ($0.scenario.postPage, $0.scenario.contentDelay)
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }

    public func myComments(lastId: Int?) async throws(TransportError) -> ContentPage<MyComment> {
        let (result, delay) = state.withLock {
            $0.requests.append(.myComments(lastId: lastId))
            return ($0.scenario.commentPage, $0.scenario.contentDelay)
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

extension MyPost {
    /// 테스트·Example용
    public static func sample(_ id: Int, thumbnail: URL? = nil, spoiler: Bool = false) -> MyPost {
        return MyPost(
            postId: id, animeTitle: "애니 \(id)", animeCoverImageUrl: nil, genre: "액션",
            title: "게시글 \(id)", content: "본문 \(id)", thumbnailURL: thumbnail, isSpoiler: spoiler,
            viewCount: id * 3, likeCount: id, commentCount: id % 4, createdAt: "2026.10.\(id)")
    }
}

extension MyComment {
    /// 테스트·Example용
    public static func sample(_ id: Int, postId: Int? = 100) -> MyComment {
        return MyComment(
            commentId: id, postId: postId, animeTitle: "애니 \(id)", animeCoverImageUrl: nil,
            genre: nil, postTitle: "게시글 \(id)", content: "댓글 \(id)", likeCount: id,
            createdAt: "2026.10.\(id)")
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
