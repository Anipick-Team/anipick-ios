import ClientCore
import CommunityClientInterface
import Foundation
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복)
public final class MockCommunityClient: CommunityClient {
    public struct BoardsRequest: Equatable, Sendable {
        public let sort: String
        public let keyword: String?
        public let lastValue: String?
        public let lastId: Int?

        public init(sort: String, keyword: String?, lastValue: String?, lastId: Int?) {
            self.sort = sort
            self.keyword = keyword
            self.lastValue = lastValue
            self.lastId = lastId
        }
    }

    public struct PostsRequest: Equatable, Sendable {
        public let seriesId: Int
        public let sort: String
        public let lastValue: String?
        public let lastId: Int?

        public init(seriesId: Int, sort: String, lastValue: String?, lastId: Int?) {
            self.seriesId = seriesId
            self.sort = sort
            self.lastValue = lastValue
            self.lastId = lastId
        }
    }

    /// 게시글 상세 화면의 요청 기록
    public enum DetailRequest: Hashable, Sendable {
        case detail(Int)
        case comments(postId: Int, lastId: Int?)
        case postLike(id: Int, liked: Bool)
        case commentLike(id: Int, liked: Bool)
        case createComment(postId: Int, content: String, parentCommentId: Int?)
        case updateComment(id: Int, content: String)
        case deletePost(Int)
        case deleteComment(Int)
        case report(ReportTarget, targetId: Int, ReportCategory)
    }

    /// 글 저장 요청 기록
    public enum SaveRequest: Equatable, Sendable {
        case upload(fileName: String, bytes: Int)
        case create(seriesId: Int, PostDraft)
        case update(id: Int, PostDraft)
    }

    private struct State {
        var boards: [Result<CommunityBoardPage, TransportError>]
        var requests: [BoardsRequest] = []
        var uploads: [Result<Int?, TransportError>] = [.success(1)]
        var saveResult: Result<PostSaveOutcome, TransportError> = .success(.saved)
        var saveRequests: [SaveRequest] = []
        var posts: [Result<CommunityPostPage, TransportError>] = []
        var postsRequests: [PostsRequest] = []
        var details: [Result<CommunityPostDetail, TransportError>] = []
        var comments: [Result<CommunityCommentPage, TransportError>] = []
        var actionFailure: TransportError?
        var detailRequests: [DetailRequest] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let delay: Duration

    public init(boards: [Result<CommunityBoardPage, TransportError>] = [], delay: Duration = .zero)
    {
        state = OSAllocatedUnfairLock(initialState: State(boards: boards))
        self.delay = delay
    }

    public var boardRequests: [BoardsRequest] {
        return state.withLock { $0.requests }
    }

    public var postsRequests: [PostsRequest] {
        return state.withLock { $0.postsRequests }
    }

    /// 게시판 글 목록 결과를 차례로 (다 쓰면 마지막 것을 반복, 없으면 빈 페이지)
    public func stubPosts(_ pages: [Result<CommunityPostPage, TransportError>]) {
        state.withLock { $0.posts = pages }
    }

    public func posts(seriesId: Int, sort: String, lastValue: String?, lastId: Int?)
        async throws(TransportError) -> CommunityPostPage
    {
        let result = state.withLock { state -> Result<CommunityPostPage, TransportError>? in
            state.postsRequests.append(
                PostsRequest(seriesId: seriesId, sort: sort, lastValue: lastValue, lastId: lastId))
            return state.posts.count > 1 ? state.posts.removeFirst() : state.posts.first
        }
        await pause()
        return try (result ?? .success(CommunityPostPage(posts: [], lastId: nil, lastValue: nil)))
            .get()
    }

    public var detailRequests: [DetailRequest] {
        return state.withLock { $0.detailRequests }
    }

    /// 상세·댓글 결과를 차례로 (다 쓰면 마지막 것을 반복). actionFailure가 있으면 좋아요·댓글·삭제·신고가 실패한다
    public func stubDetail(
        _ details: [Result<CommunityPostDetail, TransportError>] = [],
        comments: [Result<CommunityCommentPage, TransportError>] = [],
        actionFailure: TransportError? = nil
    ) {
        state.withLock {
            $0.details = details
            $0.comments = comments
            $0.actionFailure = actionFailure
        }
    }

    public func postDetail(id: Int) async throws(TransportError) -> CommunityPostDetail {
        let result = state.withLock { state -> Result<CommunityPostDetail, TransportError>? in
            state.detailRequests.append(.detail(id))
            return state.details.count > 1 ? state.details.removeFirst() : state.details.first
        }
        await pause()
        return try (result ?? .failure(.decoding)).get()
    }

    public func comments(postId: Int, lastId: Int?) async throws(TransportError)
        -> CommunityCommentPage
    {
        let result = state.withLock { state -> Result<CommunityCommentPage, TransportError>? in
            state.detailRequests.append(.comments(postId: postId, lastId: lastId))
            return state.comments.count > 1 ? state.comments.removeFirst() : state.comments.first
        }
        await pause()
        return try (result ?? .success(CommunityCommentPage(comments: [], lastId: nil))).get()
    }

    public func setPostLike(id: Int, liked: Bool) async throws(TransportError) {
        try await act(.postLike(id: id, liked: liked))
    }

    public func setCommentLike(id: Int, liked: Bool) async throws(TransportError) {
        try await act(.commentLike(id: id, liked: liked))
    }

    public func createComment(postId: Int, content: String, parentCommentId: Int?)
        async throws(TransportError)
    {
        try await act(
            .createComment(postId: postId, content: content, parentCommentId: parentCommentId))
    }

    public func updateComment(id: Int, content: String) async throws(TransportError) {
        try await act(.updateComment(id: id, content: content))
    }

    public func deletePost(id: Int) async throws(TransportError) {
        try await act(.deletePost(id))
    }

    public func deleteComment(id: Int) async throws(TransportError) {
        try await act(.deleteComment(id))
    }

    public func report(target: ReportTarget, targetId: Int, category: ReportCategory)
        async throws(TransportError)
    {
        try await act(.report(target, targetId: targetId, category))
    }

    private func act(_ request: DetailRequest) async throws(TransportError) {
        let failure = state.withLock { state in
            state.detailRequests.append(request)
            return state.actionFailure
        }
        await pause()
        if let failure {
            throw failure
        }
    }

    public var saveRequests: [SaveRequest] {
        return state.withLock { $0.saveRequests }
    }

    /// 업로드 결과를 차례로 (다 쓰면 마지막 것을 반복). 저장 결과
    public func stubSave(
        uploads: [Result<Int?, TransportError>] = [.success(1)],
        result: Result<PostSaveOutcome, TransportError> = .success(.saved)
    ) {
        state.withLock {
            $0.uploads = uploads
            $0.saveResult = result
        }
    }

    public func imageURL(id: Int) -> URL {
        return URL(string: "https://image.test/api/image/\(id)")!
    }

    public func uploadPostImage(jpeg: Data, fileName: String) async throws(TransportError) -> Int? {
        let result = state.withLock { state in
            state.saveRequests.append(.upload(fileName: fileName, bytes: jpeg.count))
            return state.uploads.count > 1 ? state.uploads.removeFirst() : state.uploads[0]
        }
        await pause()
        return try result.get()
    }

    public func createPost(seriesId: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return try await save(.create(seriesId: seriesId, draft))
    }

    public func updatePost(id: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return try await save(.update(id: id, draft))
    }

    private func save(_ request: SaveRequest) async throws(TransportError) -> PostSaveOutcome {
        let result = state.withLock { state in
            state.saveRequests.append(request)
            return state.saveResult
        }
        await pause()
        return try result.get()
    }

    private func pause() async {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
    }

    public func exploreBoards(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) async throws(TransportError) -> CommunityBoardPage {
        let result = state.withLock { state -> Result<CommunityBoardPage, TransportError>? in
            state.requests.append(
                BoardsRequest(sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId))
            return state.boards.count > 1 ? state.boards.removeFirst() : state.boards.first
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try (result ?? .success(CommunityBoardPage(boards: [], lastId: nil, lastValue: nil)))
            .get()
    }
}

extension CommunityBoard {
    /// 테스트·Example용
    public static func sample(_ id: Int, genres: [String] = ["액션", "판타지"]) -> CommunityBoard {
        return CommunityBoard(seriesId: id, title: "애니 \(id)", coverImageUrl: nil, genres: genres)
    }
}

extension CommunityPost {
    /// 테스트·Example용
    public static func sample(_ id: Int, isSpoiler: Bool = false, imageCount: Int = 0)
        -> CommunityPost
    {
        return CommunityPost(
            id: id, authorName: "작성자 \(id)", authorImageURL: nil, date: "2026.10.30",
            title: "글 \(id)", content: "내용 \(id)",
            thumbnailURL: imageCount > 0 ? URL(string: "https://image.test/api/image/\(id)") : nil,
            imageCount: imageCount, likeCount: id, commentCount: 2, isSpoiler: isSpoiler)
    }
}

extension CommunityPostDetail {
    /// 테스트·Example용
    public static func sample(
        _ id: Int, seriesId: Int = 7, isMine: Bool = false, isLiked: Bool = false,
        likeCount: Int = 3,
        imageIds: [Int] = []
    ) -> CommunityPostDetail {
        return CommunityPostDetail(
            postId: id, seriesId: seriesId, animeTitle: "애니", authorName: "작성자",
            authorImageURL: nil,
            date: "2026.10.30", isSpoiler: false, imageIds: imageIds,
            imageURLs: imageIds.map { URL(string: "https://image.test/api/image/\($0)")! },
            title: "제목 \(id)", body: "본문 \(id)", viewCount: 10, likeCount: likeCount,
            commentCount: 2,
            isLiked: isLiked, isMine: isMine)
    }
}

extension CommunityComment {
    /// 테스트·Example용
    public static func sample(
        _ id: Int, isMine: Bool = false, isLiked: Bool = false, likeCount: Int = 1,
        replies: [CommunityComment] = []
    ) -> CommunityComment {
        return CommunityComment(
            id: id, authorName: "댓글러 \(id)", authorImageURL: nil, date: "10.30",
            content: "댓글 \(id)",
            likeCount: likeCount, isLiked: isLiked, isMine: isMine, replies: replies)
    }
}
