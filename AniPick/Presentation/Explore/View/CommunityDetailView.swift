//
//  CommunityDetailView.swift
//  AniPick
//

import SwiftUI

// MARK: - Dummy Models (TODO: API 연결 시 ViewModel로 분리)
struct CommunityDetailPost {
    let authorName: String
    let date: String
    let isSpoiler: Bool
    let imageUrls: [String]
    let title: String
    let body: String
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
}

struct CommunityComment: Identifiable {
    let id: Int
    let authorName: String
    let date: String
    let content: String
    let likeCount: Int
    let replies: [CommunityReply]
}

struct CommunityReply: Identifiable {
    let id: Int
    let authorName: String
    let date: String
    let content: String
    let likeCount: Int
}

struct CommunityDetailView: View {
    @EnvironmentObject private var navigationManager: NavigationManager

    @State private var currentImageIndex: Int = 0

    // TODO: API 연결 시 ViewModel로 분리
    private let post = CommunityDetailPost(
        authorName: "작성자 닉네임",
        date: "2024.01.23",
        isSpoiler: true,
        imageUrls: ["", "", "", "", ""],
        title: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나아만아아만 기재부 도이는, 난산딜저다.",
        body: "글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용 글내용",
        viewCount: 0,
        likeCount: 0,
        commentCount: 0
    )

    private let comments: [CommunityComment] = [
        CommunityComment(
            id: 0,
            authorName: "작성자 닉네임",
            date: "2024.01.23",
            content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나아안아아만 기재부 도이는, 난산딜저다.",
            likeCount: 0,
            replies: [
                CommunityReply(
                    id: 0,
                    authorName: "작성자 닉네임",
                    date: "2024.01.23",
                    content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나아안아아만 기재부 도이는, 난산딜저다.",
                    likeCount: 0
                ),
                CommunityReply(
                    id: 1,
                    authorName: "작성자 닉네임",
                    date: "2024.01.23",
                    content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나아안아아만 기재부 도이는, 난산딜저다.",
                    likeCount: 0
                )
            ]
        ),
        CommunityComment(
            id: 1,
            authorName: "작성자 닉네임",
            date: "2024.01.23",
            content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아서 나온긂셍 즈나아안아아만 기재부 도이는, 난산딜저다.",
            likeCount: 0,
            replies: []
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            navigationHeader()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // 메인 포스트 카드
                    mainPostCard()

                    // 댓글 + 대댓글 목록
                    ForEach(comments) { comment in
                        commentCell(comment)

                        ForEach(comment.replies) { reply in
                            replyCell(reply)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            commentInputBar()
        }
        .background(Color.gray7)
        .navigationBarHidden(true)
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
                // TODO: 더보기
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
                authorAvatar()

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
                        Rectangle()
                            .foregroundColor(.gray5)
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
                .foregroundColor(.gray6)
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
                    // TODO: 좋아요
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                            .foregroundColor(.gray6)
                        Text("좋아요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray6)
                    }
                }

                Text("  |  ").font(.system(size: 14)).foregroundColor(.gray6)

                Button {
                    // TODO: 댓글
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
                    // TODO: 공유
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
                authorAvatar()

                Text(comment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.anipickBlack)

                Spacer()

                Button {
                    // TODO: 더보기
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
                    // TODO: 좋아요
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                        Text("좋아요")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
                    }
                }

                Text("  |  ").font(.system(size: 13)).foregroundColor(.gray6)

                Button {
                    // TODO: 댓글
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
                    authorAvatar()

                    Text(reply.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.anipickBlack)

                    Spacer()

                    Button {
                        // TODO: 더보기
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
                    // TODO: 좋아요
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart")
                            .font(.system(size: 13))
                            .foregroundColor(.gray6)
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
        HStack(spacing: 0) {
            Text("댓글을 작성해 주세요.")
                .font(.system(size: 14))
                .foregroundColor(.gray6)

            Spacer()

            Button {
                // TODO: 입력창 확장
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray6)
            }
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

    // MARK: - 공통 아바타
    @ViewBuilder
    private func authorAvatar() -> some View {
        Circle()
            .foregroundColor(.gray5)
            .frame(width: 36, height: 36)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
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
