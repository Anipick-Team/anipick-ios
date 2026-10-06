//
//  MyContentView.swift
//  AniPick
//

import SwiftUI

// MARK: - 화면 모델
struct MyPost: Identifiable {
    let id: Int
    let animeTitle: String
    let animeTag: String
    let animeImageUrl: String?
    let date: String
    let title: String
    let body: String
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
    let isSpoiler: Bool
    let attachedImageUrl: String?
}

struct MyCommentItem: Identifiable {
    let id: Int
    let postId: Int?
    let animeTitle: String
    let animeTag: String
    let animeImageUrl: String?
    let date: String
    let postTitle: String   // 댓글이 달린 게시글 제목
    let content: String
    let likeCount: Int
}

enum MyContentTab: String, CaseIterable {
    case posts = "내 게시글"
    case comments = "내 댓글"
}

@MainActor
final class MyContentViewModel: ObservableObject {
    @Published private(set) var posts: [MyPost] = []
    @Published private(set) var comments: [MyCommentItem] = []
    @Published private(set) var totalCount = 0
    @Published private(set) var isLoading = false

    private var postCursor: MyCommunityCursor?
    private var commentCursor: MyCommunityCursor?

    func fetch(tab: MyContentTab, reset: Bool = false) {
        if reset {
            if tab == .posts { posts.removeAll(); postCursor = nil }
            else { comments.removeAll(); commentCursor = nil }
        }

        guard !isLoading else { return }
        isLoading = true

        Task { [weak self] in
            guard let self else { return }
            do {
                if tab == .posts {
                    let response = try await CommunityAPIService.shared.myPosts(lastId: postCursor?.lastId)
                    let items = (response.result?.posts ?? []).map { Self.map($0) }
                    self.posts.append(contentsOf: items)
                    self.postCursor = response.result?.cursor
                    self.totalCount = response.result?.count ?? self.posts.count
                    DLog("내 게시글 조회 완료 - count: \(items.count)")
                } else {
                    let response = try await CommunityAPIService.shared.myComments(lastId: commentCursor?.lastId)
                    let items = (response.result?.comments ?? []).map { Self.map($0) }
                    self.comments.append(contentsOf: items)
                    self.commentCursor = response.result?.cursor
                    self.totalCount = response.result?.count ?? self.comments.count
                    DLog("내 댓글 조회 완료 - count: \(items.count)")
                }
            } catch {
                DLog("내 콘텐츠 조회 실패 - tab: \(tab.rawValue), error: \(error)")
            }
            self.isLoading = false
        }
    }

    func loadMoreIfNeeded(tab: MyContentTab, currentId: Int) {
        let lastId = tab == .posts ? posts.last?.id : comments.last?.id
        guard currentId == lastId else { return }

        if tab == .posts {
            guard postCursor?.lastId != nil else { return }
        } else {
            guard commentCursor?.lastId != nil else { return }
        }
        fetch(tab: tab)
    }

    private static func imageURL(for id: Int) -> String {
        "\(NetworkManager.baseUrl)api/image/\(id)"
    }

    private static func map(_ dto: MyCommunityPost) -> MyPost {
        MyPost(
            id: dto.postId,
            animeTitle: dto.animeTitle ?? "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: dto.animeCoverImageUrl,
            date: dto.createdAt ?? "",
            title: dto.title ?? "",
            body: dto.content ?? "",
            viewCount: dto.viewCount ?? 0,
            likeCount: dto.likeCount ?? 0,
            commentCount: dto.commentCount ?? 0,
            isSpoiler: dto.isSpoiler ?? false,
            attachedImageUrl: dto.thumbnailImageId.map { imageURL(for: $0) }
        )
    }

    private static func map(_ dto: MyCommunityComment) -> MyCommentItem {
        MyCommentItem(
            id: dto.commentId,
            postId: dto.postId,
            animeTitle: dto.animeTitle ?? "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: dto.animeCoverImageUrl,
            date: dto.createdAt ?? "",
            postTitle: dto.postTitle ?? "게시글제목",
            content: dto.content ?? "",
            likeCount: dto.likeCount ?? 0
        )
    }
}

struct MyContentView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var viewModel = MyContentViewModel()
    @State private var selectedTab: MyContentTab = .posts

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 네비게이션 헤더
            NavigationBackButtonView(title: "내 콘텐츠") {
                navigationManager.pop()
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 16)

            sectionDivider()
                .padding(.horizontal, -20)

            // 탭 바 (내 게시글 | 내 댓글)
            tabBarView()
                .padding(.horizontal, -20)

            // 총 개수
            Text("총 \(viewModel.totalCount)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // 컨텐츠
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if selectedTab == .posts {
                        ForEach(viewModel.posts) { post in
                            postCell(post)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    DLog("내 콘텐츠 게시글 선택 - postId: \(post.id)")
                                    navigationManager.push(route: .communityDetail(postId: post.id))
                                }
                                .onAppear { viewModel.loadMoreIfNeeded(tab: .posts, currentId: post.id) }
                        }
                    } else {
                        ForEach(viewModel.comments) { comment in
                            commentCell(comment)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard let postId = comment.postId else {
                                        DLog("내 댓글 게시글 이동 실패 - postId 없음, commentId: \(comment.id)")
                                        return
                                    }
                                    DLog("내 댓글 게시글 선택 - postId: \(postId), commentId: \(comment.id)")
                                    navigationManager.push(route: .communityDetail(postId: postId))
                                }
                                .onAppear { viewModel.loadMoreIfNeeded(tab: .comments, currentId: comment.id) }
                        }
                    }
                }
            }

            appTabBar()
        }
        .padding(.horizontal, 20)
        .background(Color.gray7.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { viewModel.fetch(tab: selectedTab, reset: true) }
        .onChange(of: selectedTab) { tab in
            viewModel.fetch(tab: tab, reset: true)
        }
    }

    // MARK: - 섹션 구분선
    @ViewBuilder
    private func sectionDivider() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    @ViewBuilder
    private func appTabBar() -> some View {
        HStack(spacing: 0) {
            appTabItem(image: .homeUnfilled, title: "홈", tab: .home)
            appTabItem(image: .rankingUnfilled, title: "랭킹", tab: .ranking)
            appTabItem(image: .researchUnfilled, title: "탐색", tab: .research)
            appTabItem(image: .myInfoFilled, title: "마이", tab: .myInfo)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.gray5).frame(height: 1)
        }
        .padding(.horizontal, -20)
    }

    private func appTabItem(image: ImageResource, title: String, tab: Tab) -> some View {
        Button {
            DLog("내 콘텐츠 하단 탭 선택 - \(title)")
            navigationManager.popToRoot()
            navigationManager.push(route: .content(activeTab: tab))
        } label: {
            VStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text(title)
                    .customFontStyle(size: 11, color: tab == .myInfo ? .anipickPrimary : .gray6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 탭 바
    @ViewBuilder
    private func tabBarView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(MyContentTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.system(
                                    size: 16,
                                    weight: selectedTab == tab ? .semibold : .regular
                                ))
                                .foregroundColor(selectedTab == tab ? .anipickBlack : .gray6)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)

                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == tab ? .anipickBlack : .clear)
                        }
                    }
                }
            }

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundColor(.gray5)
        }
    }

    // MARK: - 게시글 셀
    @ViewBuilder
    private func postCell(_ post: MyPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // 상단: 애니 썸네일 + 제목 + 태그
            HStack(alignment: .top, spacing: 14) {
                animeThumbnail(url: post.animeImageUrl)

                VStack(alignment: .leading, spacing: 8) {
                    Text(post.animeTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.anipickBlack)
                        .lineLimit(1)

                    tagChip(post.animeTag)
                }
            }

            // 날짜
            Text(post.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)

            // 제목
            Text(post.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.anipickBlack)
                .lineLimit(2)

            // 본문 + 첨부 이미지
                    if let attachedImageUrl = post.attachedImageUrl {
                HStack(alignment: .top, spacing: 10) {
                    Text(post.body)
                        .font(.system(size: 13))
                        .foregroundColor(.gray6)
                        .lineLimit(3)

                    Spacer()

                    attachedThumbnail(url: attachedImageUrl)
                }
            } else {
                Text(post.body)
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
                    .lineLimit(2)
            }

            // 통계 + 스포일러
            HStack(spacing: 0) {
                statItem(icon: "eye", count: post.viewCount)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem(icon: "heart", count: post.likeCount)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem(icon: "bubble.left", count: post.commentCount)

                Spacer()

                if post.isSpoiler {
                    Text("스포일러")
                        .font(.system(size: 12))
                        .foregroundColor(.anipickPrimary)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 댓글 셀
    @ViewBuilder
    private func commentCell(_ comment: MyCommentItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // 상단: 애니 썸네일 + 제목 + 태그
            HStack(alignment: .top, spacing: 14) {
                animeThumbnail(url: comment.animeImageUrl)

                VStack(alignment: .leading, spacing: 8) {
                    Text(comment.animeTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.anipickBlack)
                        .lineLimit(1)

                    tagChip(comment.animeTag)
                }
            }

            // 날짜
            Text(comment.date)
                .font(.system(size: 12))
                .foregroundColor(.gray6)

            // 댓글이 달린 게시글 제목
            Text(comment.postTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.anipickBlack)
                .lineLimit(1)

            // 댓글 내용 (회색, 2줄 제한)
            Text(comment.content)
                .font(.system(size: 13))
                .foregroundColor(.gray6)
                .lineLimit(2)

            // 좋아요 수
            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
                Text("\(comment.likeCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 공통 컴포넌트

    @ViewBuilder
    private func animeThumbnail(url: String?) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 110, height: 88)
            .overlay(
                Group {
                    if let url, let imageURL = URL(string: url) {
                        AsyncImage(url: imageURL) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Image(.animeThumbnail).resizable().scaledToFit()
                            }
                        }
                    } else {
                        Image(.animeThumbnail).resizable().scaledToFit()
                    }
                }
                .frame(width: 110, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
    }

    @ViewBuilder
    private func attachedThumbnail(url: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 80, height: 70)
            .overlay(
                CommunityRemoteImage(urlString: url)
                .frame(width: 80, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
    }

    @ViewBuilder
    private func tagChip(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 12))
            .foregroundColor(.anipickPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.anipickPrimary, lineWidth: 1)
            )
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
