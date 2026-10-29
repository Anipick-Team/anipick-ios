import Combine
import CommunityClientInterface
import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `CommunityDetailView`와 같은 배치. 키보드 포커스는 State와 양방향으로 맞춘다.
struct CommunityPostView: View {
    @State private var store: Store<CommunityPostReducer>
    @FocusState private var isCommentFocused: Bool
    private let postUpdates: AnyPublisher<Int, Never>

    init(
        state: CommunityPostReducer.State, reducer: CommunityPostReducer,
        postUpdates: AnyPublisher<Int, Never>
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.postUpdates = postUpdates
    }

    private var state: CommunityPostReducer.State {
        return store.state
    }

    private var post: CommunityPostDetail {
        return state.displayedPost
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationHeader()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let errorMessage = state.errorMessage, state.post == nil {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.gray6)
                            Button("다시 시도") {
                                store.send(.retryTapped)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.anipickPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        mainPostCard()

                        ForEach(state.comments) { comment in
                            commentCell(comment)
                                .onAppear {
                                    store.send(.commentAppeared(comment))
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
                // 빈 곳 탭 시 키보드 숨김 (버튼 등 자식 뷰의 동작이 우선)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.backgroundTapped)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            commentInputBar()
        }
        .overlay {
            if state.isShowingReport {
                reportPopup()
            }
        }
        .overlay(alignment: .bottom) {
            if let feedbackMessage = state.feedbackMessage {
                CommunityToast(message: feedbackMessage)
                    .padding(.bottom, 76)
            }
        }
        .background(Color.gray7)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            store.send(.appeared)
        }
        // 수정 화면에서 저장하고 돌아오면 바뀐 내용을 다시 불러온다
        .onReceive(postUpdates) { postId in
            store.send(.postUpdated(postId))
        }
        .onChange(of: state.isCommentFocused) { _, isFocused in
            isCommentFocused = isFocused
        }
        .onChange(of: isCommentFocused) { _, isFocused in
            if isFocused != store.state.isCommentFocused {
                store.send(.commentFocusChanged(isFocused))
            }
        }
        .confirmationDialog(
            "게시글 메뉴",
            isPresented: Binding(
                get: { store.state.isShowingPostActions },
                set: { store.send(.postActionsPresentedChanged($0)) }),
            titleVisibility: .visible
        ) {
            if post.isMine {
                Button("게시글 수정") {
                    store.send(.editPostTapped)
                }
                Button("게시글 삭제", role: .destructive) {
                    store.send(.deletePostTapped)
                }
            } else {
                Button("게시글 신고", role: .destructive) {
                    store.send(.reportTapped(.post, id: state.postId))
                }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog(
            "댓글 메뉴",
            isPresented: Binding(
                get: { store.state.isShowingCommentActions },
                set: { store.send(.commentActionsPresentedChanged($0)) }),
            titleVisibility: .visible
        ) {
            if let actionComment = state.actionComment {
                if actionComment.isMine {
                    Button("댓글 수정") {
                        store.send(.editCommentTapped)
                    }
                    Button("댓글 삭제", role: .destructive) {
                        store.send(.deleteCommentTapped)
                    }
                } else {
                    Button("댓글 신고", role: .destructive) {
                        store.send(.reportTapped(.comment, id: actionComment.id))
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func navigationHeader() -> some View {
        return HStack {
            Button {
                store.send(.backTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.anipickBlack)
            }

            Spacer()

            Button {
                store.send(.postMenuTapped)
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

    private func mainPostCard() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                CommunityProfileAvatar(imageURL: post.authorImageURL)

                Text(post.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.anipickBlack)

                Spacer()

                if post.isSpoiler {
                    SpoilerTag()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // 날짜 (아바타와 같은 x 정렬, 별도 행)
            Text(post.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 14)

            if !post.imageURLs.isEmpty {
                imageCarousel()
            }

            Text(post.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.anipickBlack)
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                // 본문이 없으면 본문 아래 여백을 제목이 대신 가진다
                .padding(.bottom, post.body.isEmpty ? 14 : 0)

            if !post.body.isEmpty {
                Text(post.body)
                    .font(.system(size: 13))
                    .foregroundColor(.gray4)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
            }

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

            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray7)

            // 액션 바 (좋아요 | 공유)
            HStack(spacing: 0) {
                Button {
                    store.send(.postLikeTapped)
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

                Spacer()

                Button {
                    store.send(.shareTapped)
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

    private func imageCarousel() -> some View {
        return VStack(spacing: 0) {
            TabView(
                selection: Binding(
                    get: { store.state.currentImageIndex },
                    set: { store.send(.imageIndexChanged($0)) })
            ) {
                ForEach(0..<post.imageURLs.count, id: \.self) { index in
                    ProtectedRemoteImage(url: post.imageURLs[index], contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 200)

            HStack(spacing: 6) {
                ForEach(0..<post.imageURLs.count, id: \.self) { index in
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(state.currentImageIndex == index ? .anipickBlack : .gray5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
    }

    private func commentHeader(_ comment: CommunityComment) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                CommunityProfileAvatar(imageURL: comment.authorImageURL)

                Text(comment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.anipickBlack)

                Spacer()

                Button {
                    // 답글도 replies 없이 같은 메뉴를 쓴다
                    var target = comment
                    target.replies = []
                    store.send(.commentMenuTapped(target))
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.gray6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Text(comment.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)

            Text(comment.content)
                .font(.system(size: 14))
                .foregroundColor(.anipickBlack)
                .lineLimit(nil)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
    }

    private func likeButton(_ comment: CommunityComment) -> some View {
        return Button {
            // 답글 좋아요도 댓글과 같은 엔드포인트를 쓴다
            store.send(.commentLikeTapped(id: comment.id, isLiked: comment.isLiked))
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
    }

    private func commentCell(_ comment: CommunityComment) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            commentHeader(comment)

            HStack(spacing: 0) {
                likeButton(comment)

                Text("  |  ").font(.system(size: 13)).foregroundColor(.gray6)

                Button {
                    store.send(.replyTapped(commentId: comment.id))
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

    private func replyCell(_ reply: CommunityComment) -> some View {
        return HStack(alignment: .top, spacing: 8) {
            // ↳ 화살표 (카드 바깥 왼쪽)
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 13))
                .foregroundColor(.gray6)
                .frame(width: 20)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 0) {
                commentHeader(reply)

                // 좋아요만 (답글에는 답글을 달 수 없다)
                likeButton(reply)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private func commentInputBar() -> some View {
        let isCommentBlank = state.isCommentBlank
        return HStack(spacing: 8) {
            HStack(spacing: 8) {
                // 다크 모드에서도 보이도록 placeholder·입력 글자 색을 직접 지정
                ZStack(alignment: .leading) {
                    if state.commentText.isEmpty {
                        Text(state.commentPlaceholder)
                            .font(.system(size: 14))
                            .foregroundColor(.gray4)
                            .allowsHitTesting(false)
                    }

                    TextField(
                        "",
                        text: Binding(
                            get: { store.state.commentText },
                            set: { store.send(.commentTextChanged($0)) })
                    )
                    .font(.system(size: 14))
                    .foregroundColor(.anipickBlack)
                    .tint(.anipickPrimary)
                    .focused($isCommentFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        store.send(.submitTapped)
                    }
                }

                Button {
                    store.send(.submitTapped)
                } label: {
                    if state.isSubmittingComment {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(.chevronUp)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isCommentBlank ? .gray4 : .anipickPrimary)
                    }
                }
                .disabled(state.isSubmittingComment || isCommentBlank)
                .accessibilityLabel("댓글 등록")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray5)
            .cornerRadius(8)

            if state.replyTargetId != nil {
                Button("취소") {
                    store.send(.replyCancelTapped)
                }
                .font(.system(size: 12))
                .foregroundColor(.gray4)
            }

            if state.editingCommentId != nil {
                Button("취소") {
                    store.send(.editCancelTapped)
                }
                .font(.system(size: 12))
                .foregroundColor(.gray4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray7),
            alignment: .top
        )
    }

    private func reportPopup() -> some View {
        return ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture {
                    store.send(.reportCloseTapped)
                }

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
                    store.send(.reportDropdownTapped)
                } label: {
                    HStack {
                        Text(state.selectedReportCategory?.displayName ?? "신고 유형 선택")
                            .font(.system(size: 17))
                            .foregroundColor(
                                state.selectedReportCategory == nil ? .gray6 : .anipickBlack)
                        Spacer()
                        Image(
                            systemName: state.isReportDropdownExpanded
                                ? "chevron.up" : "chevron.down"
                        )
                        .foregroundColor(.anipickBlack)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(Color.gray7)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                if state.isReportDropdownExpanded {
                    VStack(spacing: 0) {
                        ForEach(ReportCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                store.send(.reportCategorySelected(category))
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.anipickBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Color.gray7)
                    .padding(.horizontal, 20)
                }

                HStack(spacing: 0) {
                    Button("닫기") {
                        store.send(.reportCloseTapped)
                    }
                    .foregroundColor(.gray6)

                    Rectangle().fill(Color.gray5).frame(width: 1, height: 28).padding(
                        .horizontal, 28)

                    Button("신고하기") {
                        store.send(.reportSubmitTapped)
                    }
                    .foregroundColor(state.selectedReportCategory == nil ? .gray5 : .anipickPrimary)
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

    private func statItem(icon: String, count: Int) -> some View {
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray6)
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.gray6)
        }
    }
}
