//
//  CommunityDetailView.swift
//  AniPick
//

import SwiftUI

// MARK: - 화면 모델
struct CommunityDetailPost {
    let postId: Int
    let seriesId: Int
    let animeTitle: String
    let authorName: String
    let authorImageUrl: String?
    let date: String
    let isSpoiler: Bool
    let imageUrls: [String]
    let imageIds: [Int]
    let title: String
    let body: String
    let viewCount: Int
    var likeCount: Int
    let commentCount: Int
    var isLiked: Bool
    let isMine: Bool
}

struct CommunityComment: Identifiable {
    let id: Int
    let authorName: String
    let date: String
    let content: String
    let authorImageUrl: String?
    var likeCount: Int
    var isLiked: Bool
    let isMine: Bool
    var replies: [CommunityReply]
}

struct CommunityReply: Identifiable {
    let id: Int
    let authorName: String
    let date: String
    let content: String
    let authorImageUrl: String?
    var likeCount: Int
    var isLiked: Bool
    let isMine: Bool
}

@MainActor
final class CommunityDetailViewModel: ObservableObject {
    @Published private(set) var post: CommunityDetailPost?
    @Published private(set) var comments: [CommunityComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSubmittingComment = false
    @Published private(set) var feedbackMessage: String?

    private let postId: Int
    var postID: Int { postId }
    private var commentsCursor: CommunityCursor?

    init(postId: Int) {
        self.postId = postId
        fetch()
    }

    func fetch() {
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                async let detailResponse = CommunityAPIService.shared.postDetail(postId: postId)
                async let commentsResponse = CommunityAPIService.shared.comments(postId: postId)
                let (detail, comments) = try await (detailResponse, commentsResponse)

                guard let detailDTO = detail.result else {
                    throw NSError(domain: "CommunityDetail", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "게시글 상세 데이터가 없습니다."])
                }

                self.post = Self.map(detailDTO)
                self.comments = (comments.result?.comments ?? []).map { Self.map($0) }
                self.commentsCursor = comments.result?.cursor
                self.isLoading = false
                DLog("커뮤니티 상세 조회 완료 - postId: \(postId), comments: \(self.comments.count)")
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                DLog("커뮤니티 상세 조회 실패 - postId: \(postId), error: \(error)")
            }
        }
    }

    func loadMoreCommentsIfNeeded(current comment: CommunityComment) {
        guard comment.id == comments.last?.id,
              !isLoading,
              !isLoadingMore,
              let lastId = commentsCursor?.lastId else { return }

        isLoadingMore = true

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await CommunityAPIService.shared.comments(
                    postId: postId,
                    lastId: lastId
                )
                let nextComments = (response.result?.comments ?? []).map(Self.map)
                self.comments.append(contentsOf: nextComments)
                self.commentsCursor = response.result?.cursor
                DLog("커뮤니티 댓글 추가 조회 완료 - postId: \(postId), added: \(nextComments.count)")
            } catch {
                DLog("커뮤니티 댓글 추가 조회 실패 - postId: \(postId), error: \(error)")
            }

                self.isLoadingMore = false
        }
    }

    func togglePostLike() {
        guard let post else { return }

        let targetLiked = !post.isLiked
        let previousLikeCount = post.likeCount
        self.post?.isLiked = targetLiked
        self.post?.likeCount = max(0, previousLikeCount + (targetLiked ? 1 : -1))

        Task { [weak self] in
            guard let self else { return }
            do {
                if targetLiked {
                    _ = try await CommunityAPIService.shared.likePost(postId: postId)
                } else {
                    _ = try await CommunityAPIService.shared.unlikePost(postId: postId)
                }
                DLog("커뮤니티 게시글 좋아요 \(targetLiked ? "등록" : "취소") 완료 - postId: \(postId)")
            } catch {
                self.post?.isLiked = !targetLiked
                self.post?.likeCount = previousLikeCount
                DLog("커뮤니티 게시글 좋아요 실패 - postId: \(postId), error: \(error)")
            }
        }
    }

    func createComment(content: String, parentCommentId: Int? = nil) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty, !isSubmittingComment else { return }

        isSubmittingComment = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let request = CommunityCommentRequest(content: trimmedContent, parentCommentId: parentCommentId)
                _ = try await CommunityAPIService.shared.createComment(postId: postId, body: request)
                DLog("커뮤니티 댓글 등록 성공 - postId: \(postId)")
                self.isSubmittingComment = false
                self.feedbackMessage = parentCommentId == nil ? "댓글이 등록되었습니다." : "답글이 등록되었습니다."
                self.fetch()
            } catch {
                self.isSubmittingComment = false
                DLog("커뮤니티 댓글 등록 실패 - postId: \(postId), error: \(error)")
            }
        }
    }

    func updateComment(commentId: Int, content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty, !isSubmittingComment else { return }

        isSubmittingComment = true
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await CommunityAPIService.shared.updateComment(
                    commentId: commentId,
                    body: CommunityCommentRequest(content: trimmedContent, parentCommentId: nil)
                )
                DLog("커뮤니티 댓글 수정 성공 - commentId: \(commentId)")
                self.isSubmittingComment = false
                self.feedbackMessage = "댓글이 수정되었습니다."
                self.fetch()
            } catch {
                self.isSubmittingComment = false
                DLog("커뮤니티 댓글 수정 실패 - commentId: \(commentId), error: \(error)")
            }
        }
    }

    func toggleCommentLike(commentId: Int, isLiked: Bool) {
        updateCommentLike(commentId: commentId, isLiked: !isLiked)
        Task { [weak self] in
            guard let self else { return }
            do {
                if isLiked {
                    _ = try await CommunityAPIService.shared.unlikeComment(commentId: commentId)
                } else {
                    _ = try await CommunityAPIService.shared.likeComment(commentId: commentId)
                }
                DLog("커뮤니티 댓글 좋아요 \(isLiked ? "취소" : "등록") 완료 - commentId: \(commentId)")
            } catch {
                self.updateCommentLike(commentId: commentId, isLiked: isLiked)
                DLog("커뮤니티 댓글 좋아요 실패 - commentId: \(commentId), error: \(error)")
            }
        }
    }

    func deletePost() async throws {
        _ = try await CommunityAPIService.shared.deletePost(postId: postId)
        DLog("커뮤니티 게시글 삭제 성공 - postId: \(postId)")
        feedbackMessage = "게시글이 삭제되었습니다."
    }

    func deleteComment(commentId: Int) async throws {
        _ = try await CommunityAPIService.shared.deleteComment(commentId: commentId)
        DLog("커뮤니티 댓글 삭제 성공 - commentId: \(commentId)")
        feedbackMessage = "댓글이 삭제되었습니다."
        fetch()
    }

    func report(targetType: CommunityReportTarget, targetId: Int, category: CommunityReportCategory) async {
        do {
            _ = try await CommunityAPIService.shared.report(
                CommunityReportRequest(targetType: targetType, targetId: targetId, reportCategory: category)
            )
            DLog("커뮤니티 신고 성공 - targetType: \(targetType.rawValue), targetId: \(targetId), category: \(category.rawValue)")
            feedbackMessage = "신고가 접수되었습니다."
        } catch {
            DLog("커뮤니티 신고 실패 - targetType: \(targetType.rawValue), targetId: \(targetId), category: \(category.rawValue), error: \(error)")
        }
    }

    func clearFeedback() {
        feedbackMessage = nil
    }

    private func updateCommentLike(commentId: Int, isLiked: Bool) {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            let wasLiked = comments[index].isLiked
            comments[index].isLiked = isLiked
            comments[index].likeCount = max(0, comments[index].likeCount + (isLiked == wasLiked ? 0 : (isLiked ? 1 : -1)))
            return
        }

        for index in comments.indices {
            guard let replyIndex = comments[index].replies.firstIndex(where: { $0.id == commentId }) else { continue }
            let wasLiked = comments[index].replies[replyIndex].isLiked
            comments[index].replies[replyIndex].isLiked = isLiked
            comments[index].replies[replyIndex].likeCount = max(0, comments[index].replies[replyIndex].likeCount + (isLiked == wasLiked ? 0 : (isLiked ? 1 : -1)))
            return
        }
    }

    private static func imageURL(for id: Int) -> String {
        "\(NetworkManager.baseUrl)api/image/\(id)"
    }

    private static func map(_ dto: CommunityPostDetailDTO) -> CommunityDetailPost {
        CommunityDetailPost(
            postId: dto.postId,
            seriesId: dto.seriesId ?? 0,
            animeTitle: dto.animeTitle ?? "애니메이션",
            authorName: dto.nickname ?? "익명",
            authorImageUrl: dto.profileImageUrl,
            date: dto.createdAt ?? "",
            isSpoiler: dto.isSpoiler ?? false,
            imageUrls: (dto.imageIds ?? []).map { imageURL(for: $0) },
            imageIds: dto.imageIds ?? [],
            title: dto.title ?? "",
            body: dto.content ?? "",
            viewCount: dto.viewCount ?? 0,
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0,
            isLiked: dto.likedByCurrentUser ?? false,
            isMine: dto.isMine ?? false
        )
    }

    private static func map(_ dto: CommunityCommentDTO) -> CommunityComment {
        CommunityComment(
            id: dto.commentId,
            authorName: dto.nickname ?? "익명",
            date: dto.createdAt ?? "",
            content: dto.isDeleted == true ? "삭제된 댓글입니다." : (dto.content ?? ""),
            authorImageUrl: dto.profileImageUrl,
            likeCount: dto.likeCount ?? 0,
            isLiked: dto.likedByCurrentUser ?? false,
            isMine: dto.isMine ?? false,
            replies: (dto.replies ?? []).map(mapReply)
        )
    }

    private static func mapReply(_ dto: CommunityCommentDTO) -> CommunityReply {
        CommunityReply(
            id: dto.commentId,
            authorName: dto.nickname ?? "익명",
            date: dto.createdAt ?? "",
            content: dto.isDeleted == true ? "삭제된 댓글입니다." : (dto.content ?? ""),
            authorImageUrl: dto.profileImageUrl,
            likeCount: dto.likeCount ?? 0,
            isLiked: dto.likedByCurrentUser ?? false,
            isMine: dto.isMine ?? false
        )
    }
}

struct CommunityDetailView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var viewModel: CommunityDetailViewModel

    @State private var currentImageIndex: Int = 0
    @State private var commentText = ""
    @State private var replyTargetId: Int?
    @State private var editingCommentId: Int?
    @State private var isShowingPostActions = false
    @State private var actionComment: CommunityComment?
    @State private var isShowingCommentActions = false
    @State private var isShowingReportCategory = false
    @State private var reportTargetType: CommunityReportTarget = .post
    @State private var reportTargetId = 0
    @State private var isReportDropdownExpanded = false
    @State private var selectedReportCategory: CommunityReportCategory?
    @FocusState private var isCommentFocused: Bool

    init(postId: Int) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(postId: postId))
    }

    private var post: CommunityDetailPost {
        viewModel.post ?? CommunityDetailPost(
            postId: viewModel.postID,
            seriesId: 0,
            animeTitle: "애니메이션",
            authorName: "",
            authorImageUrl: nil,
            date: "",
            isSpoiler: false,
            imageUrls: [],
            imageIds: [],
            title: "",
            body: viewModel.isLoading ? "불러오는 중..." : "게시글을 불러오지 못했습니다.",
            viewCount: 0,
            likeCount: 0,
            commentCount: 0,
            isLiked: false,
            isMine: false
        )
    }

    private var comments: [CommunityComment] { viewModel.comments }

    var body: some View {
        VStack(spacing: 0) {
            navigationHeader()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let errorMessage = viewModel.errorMessage, viewModel.post == nil {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.gray6)
                            Button("다시 시도") {
                                viewModel.fetch()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.anipickPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        // 메인 포스트 카드
                        mainPostCard()

                        // 댓글 + 대댓글 목록
                        ForEach(comments) { comment in
                            commentCell(comment)
                                .onAppear {
                                    viewModel.loadMoreCommentsIfNeeded(current: comment)
                                }

                            ForEach(comment.replies) { reply in
                                replyCell(reply)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            commentInputBar()
        }
        .overlay {
            if isShowingReportCategory {
                reportPopup()
            }
        }
        .overlay(alignment: .bottom) {
            if let feedbackMessage = viewModel.feedbackMessage {
                CommunityToast(message: feedbackMessage)
                    .padding(.bottom, 76)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            viewModel.clearFeedback()
                        }
                    }
            }
        }
        .background(Color.gray7)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("게시글 메뉴", isPresented: $isShowingPostActions, titleVisibility: .visible) {
            if post.isMine {
                Button("게시글 수정") {
                    guard post.seriesId != 0 else {
                        DLog("커뮤니티 게시글 수정 이동 실패 - seriesId 없음, postId: \(post.postId)")
                        return
                    }
                    navigationManager.push(
                        route: .communityEdit(
                            postId: post.postId,
                            seriesId: post.seriesId,
                            animeTitle: post.animeTitle,
                            title: post.title,
                            content: post.body,
                            isSpoiler: post.isSpoiler,
                            imageIds: post.imageIds
                        )
                    )
                }
                Button("게시글 삭제", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deletePost()
                            navigationManager.pop()
                        } catch {
                            DLog("커뮤니티 게시글 삭제 실패 - error: \(error)")
                        }
                    }
                }
            } else {
                Button("게시글 신고", role: .destructive) {
                    beginReport(targetType: .post, targetId: viewModel.postID)
                }
            }
            Button("취소", role: .cancel) { }
        }
        .confirmationDialog("댓글 메뉴", isPresented: $isShowingCommentActions, titleVisibility: .visible) {
            if let actionComment {
                if actionComment.isMine {
                    Button("댓글 수정") {
                        editingCommentId = actionComment.id
                        replyTargetId = nil
                        commentText = actionComment.content
                        isCommentFocused = true
                    }
                    Button("댓글 삭제", role: .destructive) {
                        Task {
                            do { try await viewModel.deleteComment(commentId: actionComment.id) }
                            catch { DLog("커뮤니티 댓글 삭제 실패 - error: \(error)") }
                        }
                    }
                } else {
                    Button("댓글 신고", role: .destructive) {
                        beginReport(targetType: .comment, targetId: actionComment.id)
                    }
                }
            }
            Button("취소", role: .cancel) { }
        }
    }

    // MARK: - 네비게이션 헤더
    @ViewBuilder
    private func navigationHeader() -> some View {
        HStack {
            Button {
                navigationManager.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.anipickBlack)
            }

            Spacer()

            Button {
                isShowingPostActions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(.anipickBlack)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    // MARK: - 메인 포스트 카드
    @ViewBuilder
    private func mainPostCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // 작성자 행
            HStack(alignment: .center, spacing: 10) {
                authorAvatar(imageURL: post.authorImageUrl)

                Text(post.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.anipickBlack)

                Spacer()

                if post.isSpoiler {
                    Text("스포일러")
                        .font(.system(size: 12))
                        .foregroundColor(.anipickPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.anipickPrimary, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // 날짜 (아바타와 동일한 x 정렬, 별도 행)
            Text(post.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 14)

            // 이미지 캐러셀 (카드 full-width)
            if !post.imageUrls.isEmpty {
                TabView(selection: $currentImageIndex) {
                    ForEach(0..<post.imageUrls.count, id: \.self) { idx in
                        CommunityRemoteImage(urlString: post.imageUrls[idx], contentMode: .fit)
                            .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 200)

                // 페이지 인디케이터
                HStack(spacing: 6) {
                    ForEach(0..<post.imageUrls.count, id: \.self) { idx in
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(currentImageIndex == idx ? .anipickBlack : .gray5)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }

            // 본문 제목
            Text(post.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.anipickBlack)
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // 본문 내용 (회색)
            Text(post.body)
                .font(.system(size: 13))
                .foregroundColor(.anipickBlack.opacity(0.72))
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)

            // 통계 (조회수 | 좋아요 | 댓글 수)
            HStack(spacing: 0) {
                statItem(icon: "eye", count: post.viewCount)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem(icon: "heart", count: post.likeCount)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem(icon: "bubble.left", count: post.commentCount)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // 구분선
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray7)

            // 액션 바 (좋아요 | 댓글 | 공유)
            HStack(spacing: 0) {
                Button {
                    viewModel.togglePostLike()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(post.isLiked ? .red : .gray6)
                        Text("좋아요")
                            .font(.system(size: 14))
                            .foregroundColor(post.isLiked ? .red : .gray6)
                    }
                }

                Text("  |  ").font(.system(size: 14)).foregroundColor(.gray6)

                Button {
                    isCommentFocused = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                            .foregroundColor(.gray6)
                        Text("댓글")
                            .font(.system(size: 14))
                            .foregroundColor(.gray6)
                    }
                }

                Spacer()

                Button {
                    ShareSheet.present(items: ["\(post.title)\n\(post.body)"])
                    DLog("커뮤니티 게시글 공유 실행 - postId: \(viewModel.postID)")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.gray6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 댓글 셀
    @ViewBuilder
    private func commentCell(_ comment: CommunityComment) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // 작성자 행
            HStack(alignment: .center, spacing: 10) {
                authorAvatar(imageURL: comment.authorImageUrl)

                Text(comment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.anipickBlack)

                Spacer()

                Button {
                    actionComment = comment
                    isShowingCommentActions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.gray6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // 날짜 (별도 행, 좌측 정렬)
            Text(comment.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)

            // 본문
            Text(comment.content)
                .font(.system(size: 14))
                .foregroundColor(.anipickBlack)
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            // 액션
            HStack(spacing: 0) {
                Button {
                    viewModel.toggleCommentLike(commentId: comment.id, isLiked: comment.isLiked)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(comment.isLiked ? .red : .gray6)
                        Text("좋아요")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                    }
                }

                Text("  |  ").font(.system(size: 13)).foregroundColor(.gray6)

                Button {
                    replyTargetId = comment.id
                    isCommentFocused = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                        Text("댓글")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 대댓글 셀
    @ViewBuilder
    private func replyCell(_ reply: CommunityReply) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // ↳ 화살표 (카드 바깥 왼쪽)
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 13))
                .foregroundColor(.gray6)
                .frame(width: 20)
                .padding(.top, 16)

            // 대댓글 카드
            VStack(alignment: .leading, spacing: 0) {

                // 작성자 행
                HStack(alignment: .center, spacing: 10) {
                    authorAvatar(imageURL: reply.authorImageUrl)

                    Text(reply.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.anipickBlack)

                    Spacer()

                Button {
                    actionComment = CommunityComment(
                        id: reply.id,
                        authorName: reply.authorName,
                        date: reply.date,
                        content: reply.content,
                        authorImageUrl: reply.authorImageUrl,
                        likeCount: reply.likeCount,
                        isLiked: reply.isLiked,
                        isMine: reply.isMine,
                        replies: []
                    )
                    isShowingCommentActions = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(.gray6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // 날짜
                Text(reply.date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray6)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                // 본문
                Text(reply.content)
                    .font(.system(size: 14))
                    .foregroundColor(.anipickBlack)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                // 좋아요만 (댓글 없음)
                Button {
                    // 대댓글 좋아요 API는 댓글 API와 동일한 엔드포인트를 사용합니다.
                    viewModel.toggleCommentLike(commentId: reply.id, isLiked: reply.isLiked)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: reply.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(reply.isLiked ? .red : .gray6)
                        Text("좋아요")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - 댓글 입력 바
    @ViewBuilder
    private func commentInputBar() -> some View {
        HStack(spacing: 8) {
            TextField(
                editingCommentId != nil ? "댓글을 수정해 주세요." : (replyTargetId == nil ? "댓글을 작성해 주세요." : "답글을 작성해 주세요."),
                text: $commentText
            )
                .font(.system(size: 14))
                .focused($isCommentFocused)
                .submitLabel(.send)
                .onSubmit { submitComment() }

            if replyTargetId != nil {
                Button("취소") {
                    replyTargetId = nil
                    isCommentFocused = false
                }
                .font(.system(size: 12))
                .foregroundColor(.gray6)
            }

            if editingCommentId != nil {
                Button("취소") {
                    editingCommentId = nil
                    commentText = ""
                    isCommentFocused = false
                }
                .font(.system(size: 12))
                .foregroundColor(.gray6)
            }

            Button {
                submitComment()
            } label: {
                Image(systemName: viewModel.isSubmittingComment ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray5 : .anipickPrimary)
            }
            .disabled(viewModel.isSubmittingComment || commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray7),
            alignment: .top
        )
    }

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let editingCommentId {
            viewModel.updateComment(commentId: editingCommentId, content: trimmed)
        } else {
            viewModel.createComment(content: trimmed, parentCommentId: replyTargetId)
        }
        commentText = ""
        replyTargetId = nil
        editingCommentId = nil
        isCommentFocused = false
    }

    private func beginReport(targetType: CommunityReportTarget, targetId: Int) {
        reportTargetType = targetType
        reportTargetId = targetId
        selectedReportCategory = nil
        isReportDropdownExpanded = false
        isShowingReportCategory = true
    }

    @ViewBuilder
    private func reportCategoryButton(_ title: String, category: CommunityReportCategory) -> some View {
        Button(title) {
            Task {
                await viewModel.report(
                    targetType: reportTargetType,
                    targetId: reportTargetId,
                    category: category
                )
            }
        }
    }

    @ViewBuilder
    private func reportPopup() -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { isShowingReportCategory = false }

            VStack(spacing: 0) {
                Text("신고")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.anipickBlack)
                    .padding(.top, 28)
                    .padding(.bottom, 26)

                Text("신고 유형 선택")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.anipickBlack)
                    .padding(.bottom, 12)

                Button {
                    isReportDropdownExpanded.toggle()
                } label: {
                    HStack {
                        Text(selectedReportCategory?.displayName ?? "신고 유형 선택")
                            .font(.system(size: 17))
                            .foregroundColor(selectedReportCategory == nil ? .gray6 : .anipickBlack)
                        Spacer()
                        Image(systemName: isReportDropdownExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.anipickBlack)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(Color.gray7)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                if isReportDropdownExpanded {
                    VStack(spacing: 0) {
                        reportMenuItem("욕설/비하/혐오 표현", category: .abuse)
                        reportMenuItem("개인정보 노출", category: .privacy)
                        reportMenuItem("도배/스팸/광고성 내용", category: .spam)
                        reportMenuItem("불법/유해/부적절한 내용", category: .illegal)
                        reportMenuItem("기타 운영정책 위반", category: .etc)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Color.gray7)
                    .padding(.horizontal, 20)
                }

                HStack(spacing: 0) {
                    Button("닫기") { isShowingReportCategory = false }
                        .foregroundColor(.gray6)
                    Rectangle().fill(Color.gray5).frame(width: 1, height: 28).padding(.horizontal, 28)
                    Button("신고하기") {
                        guard let selectedReportCategory else {
                            DLog("신고 유형을 선택해 주세요.")
                            return
                        }
                        isShowingReportCategory = false
                        Task {
                            await viewModel.report(targetType: reportTargetType, targetId: reportTargetId, category: selectedReportCategory)
                        }
                    }
                    .foregroundColor(selectedReportCategory == nil ? .gray5 : .anipickPrimary)
                }
                .font(.system(size: 17, weight: .medium))
                .padding(.top, 30)
                .padding(.bottom, 25)
            }
            .frame(maxWidth: 340)
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func reportMenuItem(_ title: String, category: CommunityReportCategory) -> some View {
        Button(title) {
            selectedReportCategory = category
            isReportDropdownExpanded = false
        }
        .font(.system(size: 16))
        .foregroundColor(.anipickBlack)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 공통 아바타
    @ViewBuilder
    private func authorAvatar(imageURL: String? = nil) -> some View {
        CommunityProfileAvatar(imageURL: imageURL)
    }

    @ViewBuilder
    private func statItem(icon: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.gray6)
        }
    }
}
