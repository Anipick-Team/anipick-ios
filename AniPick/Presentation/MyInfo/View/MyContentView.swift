//
//  MyContentView.swift
//  AniPick
//

import SwiftUI

// MARK: - Dummy Models (TODO: API 연결 시 ViewModel로 분리)
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

struct MyContentView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var selectedTab: MyContentTab = .posts

    // TODO: API 연결 시 ViewModel로 분리
    private let totalCount = 999

    private let posts: [MyPost] = [
        MyPost(
            id: 0,
            animeTitle: "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: nil,
            date: "2024.01.23",
            title: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나야...",
            body: "글내용 글내용 글내용 글내용 글내용",
            viewCount: 0,
            likeCount: 0,
            commentCount: 0,
            isSpoiler: true,
            attachedImageUrl: nil
        ),
        MyPost(
            id: 1,
            animeTitle: "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: nil,
            date: "2024.01.23",
            title: "한줄",
            body: "글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용...",
            viewCount: 0,
            likeCount: 0,
            commentCount: 0,
            isSpoiler: false,
            attachedImageUrl: nil
        ),
        MyPost(
            id: 2,
            animeTitle: "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: nil,
            date: "2024.01.23",
            title: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다...",
            body: "글내용 글내용 글내용 글내용 글내용",
            viewCount: 0,
            likeCount: 0,
            commentCount: 0,
            isSpoiler: false,
            attachedImageUrl: ""
        )
    ]

    private let myComments: [MyCommentItem] = (0..<3).map {
        MyCommentItem(
            id: $0,
            animeTitle: "애니메이션 제목",
            animeTag: "text",
            animeImageUrl: nil,
            date: "2024.01.23",
            postTitle: "게시글제목",
            content: "댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓글내용댓...",
            likeCount: 0
        )
    }

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
            Text("총 \(totalCount)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // 컨텐츠
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if selectedTab == .posts {
                        ForEach(posts) { post in
                            postCell(post)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray7)
                        }
                    } else {
                        ForEach(myComments) { comment in
                            commentCell(comment)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray7)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - 섹션 구분선
    @ViewBuilder
    private func sectionDivider() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
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
            if let _ = post.attachedImageUrl {
                HStack(alignment: .top, spacing: 10) {
                    Text(post.body)
                        .font(.system(size: 13))
                        .foregroundColor(.gray6)
                        .lineLimit(3)

                    Spacer()

                    attachedThumbnail()
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
    }

    // MARK: - 공통 컴포넌트

    @ViewBuilder
    private func animeThumbnail(url: String?) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 110, height: 88)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
            )
    }

    @ViewBuilder
    private func attachedThumbnail() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 80, height: 70)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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
