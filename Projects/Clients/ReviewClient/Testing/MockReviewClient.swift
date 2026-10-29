import ClientCore
import ReviewClientInterface
import os

/// 시나리오형 가짜. 결과·지연을 정해 두고 받은 요청을 기록한다 (Store 테스트·Example 앱).
public final class MockReviewClient: ReviewClient {
    public struct WrittenReview: Equatable, Sendable {
        public let animeId: Int
        public let content: String
        public let rating: Double
        public let isSpoiler: Bool

        public init(animeId: Int, content: String, rating: Double, isSpoiler: Bool) {
            self.animeId = animeId
            self.content = content
            self.rating = rating
            self.isSpoiler = isSpoiler
        }
    }

    private struct State {
        var result: Result<Void, TransportError>
        var delay: Duration
        var written: [WrittenReview] = []
        var deletedIds: [Int] = []
        var initialRatings: [[InitialRating]] = []
        var recentPages: [Result<RecentReviewPage?, TransportError>] = []
        var likeResult: Result<Bool, TransportError> = .success(true)
        var actionResult: Result<Void, TransportError> = .success(())
        var actions: [Action] = []
    }

    /// 최근 리뷰 화면의 요청 기록
    public enum Action: Equatable, Sendable {
        case recent(lastId: Int?)
        case like(id: Int, liked: Bool)
        case report(id: Int, message: String)
        case block(userId: Int)
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(result: Result<Void, TransportError> = .success(()), delay: Duration = .zero) {
        state = OSAllocatedUnfairLock(initialState: State(result: result, delay: delay))
    }

    public var actions: [Action] {
        return state.withLock { $0.actions }
    }

    /// 최근 리뷰 결과를 차례로 (다 쓰면 마지막 것을 반복, 없으면 nil). 좋아요·신고·차단 결과
    public func stubRecent(
        _ pages: [Result<RecentReviewPage?, TransportError>] = [],
        like: Result<Bool, TransportError> = .success(true),
        action: Result<Void, TransportError> = .success(())
    ) {
        state.withLock {
            $0.recentPages = pages
            $0.likeResult = like
            $0.actionResult = action
        }
    }

    public func recentReviews(lastId: Int?) async throws(TransportError) -> RecentReviewPage? {
        let (result, delay) = state.withLock {
            state -> (Result<RecentReviewPage?, TransportError>, Duration) in
            state.actions.append(.recent(lastId: lastId))
            guard let first = state.recentPages.first else {
                return (.success(nil), state.delay)
            }
            if state.recentPages.count > 1 {
                state.recentPages.removeFirst()
            }
            return (first, state.delay)
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }

    public func setReviewLike(id: Int, liked: Bool) async throws(TransportError) -> Bool {
        let (result, delay) = state.withLock {
            $0.actions.append(.like(id: id, liked: liked))
            return ($0.likeResult, $0.delay)
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }

    public func reportReview(id: Int, message: String) async throws(TransportError) {
        try state.withLock {
            $0.actions.append(.report(id: id, message: message))
            return $0.actionResult
        }
        .get()
    }

    public func blockUser(id: Int) async throws(TransportError) {
        try state.withLock {
            $0.actions.append(.block(userId: id))
            return $0.actionResult
        }
        .get()
    }

    public var written: [WrittenReview] {
        return state.withLock { $0.written }
    }

    public var initialRatings: [[InitialRating]] {
        return state.withLock { $0.initialRatings }
    }

    public func storeInitialRatings(_ ratings: [InitialRating]) async throws(TransportError) {
        try state.withLock {
            $0.initialRatings.append(ratings)
            return $0.result
        }
        .get()
    }

    public var deletedIds: [Int] {
        return state.withLock { $0.deletedIds }
    }

    public func deleteReview(id: Int) async throws(TransportError) {
        try state.withLock {
            $0.deletedIds.append(id)
            return $0.result
        }
        .get()
    }

    public func writeReview(
        animeId: Int,
        content: String,
        rating: Double,
        isSpoiler: Bool
    ) async throws(TransportError) {
        let delay = state.withLock {
            $0.written.append(
                WrittenReview(
                    animeId: animeId,
                    content: content,
                    rating: rating,
                    isSpoiler: isSpoiler
                )
            )
            return $0.delay
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        try state.withLock { $0.result }.get()
    }
}

extension RecentReview {
    /// 테스트·Example용
    public static func sample(_ id: Int, likeCount: Int? = 1, isLiked: Bool? = false)
        -> RecentReview
    {
        return RecentReview(
            reviewId: id, userId: 100 + id, animeId: 10 + id, animeTitle: "애니 \(id)",
            animeCoverImageUrl: nil,
            rating: 4.5, text: "리뷰 \(id)", nickname: "닉네임 \(id)", profileImageId: nil,
            createdAt: "2026.10.30",
            likeCount: likeCount, isLiked: isLiked)
    }
}
