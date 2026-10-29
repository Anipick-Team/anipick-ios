import DesignSystem
import MVICore
import MyInfoClientInterface
import MyInfoInterface
import SwiftUI

/// 레거시 `MyContentView`와 같은 배치
struct MyContentView: View {
    @State private var store: Store<MyContentReducer>

    init(state: MyContentReducer.State, reducer: MyContentReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: "내 콘텐츠") {
                store.send(.backTapped)
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 16)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.horizontal, -20)

            tabBar()
                .padding(.horizontal, -20)

            Text("총 \(store.state.totalCountText)개")
                .textStyle(size: 14, color: .gray8)
                .padding(.top, 14)
                .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if store.state.tab == .posts {
                        ForEach(store.state.posts, id: \.postId) { post in
                            postCell(post)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.postTapped(post))
                                }
                                .onAppear {
                                    store.send(.postAppeared(post))
                                }
                        }
                    } else {
                        ForEach(store.state.comments, id: \.commentId) { comment in
                            commentCell(comment)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.commentTapped(comment))
                                }
                                .onAppear {
                                    store.send(.commentAppeared(comment))
                                }
                        }
                    }
                }
            }

            mainTabBar()
        }
        .padding(.horizontal, 20)
        .background(Color.gray7.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            store.send(.appeared)
        }
    }

    // MARK: - 탭

    private func tabBar() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(MyContentReducer.Tab.allCases, id: \.self) { tab in
                    let isSelected = store.state.tab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = store.send(.tabSelected(tab))
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .anipickBlack : .gray6)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)

                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(isSelected ? .anipickBlack : .clear)
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

    /// 화면 아래에 따로 그리는 앱 탭 바. 누르면 그 탭으로 간다 (MC8)
    private func mainTabBar() -> some View {
        return HStack(spacing: 0) {
            mainTabItem(.homeUnfilled, "홈", .home)
            mainTabItem(.rankingUnfilled, "랭킹", .ranking)
            mainTabItem(.researchUnfilled, "탐색", .explore)
            mainTabItem(.myInfoFilled, "마이", .myInfo)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.gray5).frame(height: 1)
        }
        .padding(.horizontal, -20)
    }

    private func mainTabItem(_ image: ImageResource, _ title: String, _ tab: MainTab) -> some View {
        return Button {
            store.send(.mainTabTapped(tab))
        } label: {
            VStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text(title)
                    .textStyle(size: 11, color: tab == .myInfo ? .anipickPrimary : .gray6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 칸

    private func header(animeTitle: String?, coverURL: String?, genre: String?, date: String?)
        -> some View
    {
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                animeThumbnail(coverURL)

                VStack(alignment: .leading, spacing: 8) {
                    Text(animeTitle ?? "애니메이션 제목")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.anipickBlack)
                        .lineLimit(1)

                    if let genre, !genre.isEmpty {
                        tagChip(genre)
                    }
                }
            }

            Text(date ?? "")
                .font(.system(size: 12))
                .foregroundColor(.gray6)
        }
    }

    private func postCell(_ post: MyPost) -> some View {
        return VStack(alignment: .leading, spacing: 16) {
            header(
                animeTitle: post.animeTitle, coverURL: post.animeCoverImageUrl, genre: post.genre,
                date: post.createdAt)

            if let thumbnailURL = post.thumbnailURL {
                HStack(alignment: .top, spacing: 16) {
                    postText(post, bodyLineLimit: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    attachedThumbnail(thumbnailURL)
                }
            } else {
                postText(post, bodyLineLimit: 2)
            }

            HStack(spacing: 0) {
                statItem("eye", post.viewCount ?? 0)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem("heart", post.likeCount ?? 0)
                Text("  |  ").font(.system(size: 12)).foregroundColor(.gray6)
                statItem("bubble.left", post.commentCount ?? 0)

                Spacer()

                if post.isSpoiler ?? false {
                    Text("스포일러")
                        .textStyle(size: 12, color: .anipickPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.anipickPrimary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(8)
    }

    /// 첨부 이미지가 있으면 본문 3줄, 없으면 2줄 (MC6)
    private func postText(_ post: MyPost, bodyLineLimit: Int) -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            Text(post.title ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.anipickBlack)
                .lineLimit(2)

            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
                    .lineLimit(bodyLineLimit)
            }
        }
    }

    private func commentCell(_ comment: MyComment) -> some View {
        return VStack(alignment: .leading, spacing: 16) {
            header(
                animeTitle: comment.animeTitle, coverURL: comment.animeCoverImageUrl,
                genre: comment.genre, date: comment.createdAt)

            VStack(alignment: .leading, spacing: 8) {
                Text(comment.postTitle ?? "게시글제목")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.anipickBlack)
                    .lineLimit(1)

                Text(comment.content ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
                    .lineLimit(2)
            }

            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
                Text("\(comment.likeCount ?? 0)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray6)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(8)
    }

    // MARK: - 공통

    private func animeThumbnail(_ url: String?) -> some View {
        return RoundedRectangle(cornerRadius: 8)
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

    private func attachedThumbnail(_ url: URL) -> some View {
        return RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 80, height: 70)
            .overlay(
                ProtectedRemoteImage(url: url)
                    .frame(width: 80, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            )
    }

    private func tagChip(_ tag: String) -> some View {
        return Text(tag)
            .font(.system(size: 12))
            .foregroundColor(.anipickPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.anipickPrimary.opacity(0.1))
            .cornerRadius(4)
    }

    private func statItem(_ icon: String, _ count: Int) -> some View {
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
