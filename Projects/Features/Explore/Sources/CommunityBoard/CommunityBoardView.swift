import CommunityClientInterface
import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `CommunityView`와 같은 배치
struct CommunityBoardView: View {
    @State private var store: Store<CommunityBoardReducer>

    init(state: CommunityBoardReducer.State, reducer: CommunityBoardReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: CommunityBoardReducer.State {
        return store.state
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                BackNavigationBar(title: "커뮤니티") {
                    store.send(.backTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        animeInfoHeader()
                            .background(Color.white)
                        filterBar()
                            .background(Color.white)
                        spoilerBar()
                            .background(Color.white)
                        LazyVStack(spacing: 12) {
                            if state.isLoading && state.posts.isEmpty {
                                ProgressView()
                                    .padding(.top, 40)
                            } else if let errorMessage = state.errorMessage, state.posts.isEmpty {
                                retryState(message: errorMessage)
                            } else if state.posts.isEmpty {
                                Text("아직 작성된 게시글이 없어요.\n첫 글을 남겨보세요.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray6)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 40)
                            } else {
                                ForEach(state.visiblePosts) { post in
                                    postCell(post)
                                        .onAppear {
                                            store.send(.postAppeared(post))
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 80)
                    }
                    .background(Color.gray7)
                }
                .background(Color.gray7)
            }
            .background(Color.white)

            Button {
                store.send(.writeTapped)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.anipickPrimary)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        // 탐색의 커뮤니티 목록에서는 탭을 유지하고, 게시판에 진입한 뒤에는 숨긴다 (레거시 그대로)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func filterBar() -> some View {
        return HStack(spacing: 6) {
            ForEach(CommunityBoardReducer.Filter.allCases, id: \.self) { filter in
                let isSelected = state.filter == filter
                Button {
                    store.send(.filterSelected(filter))
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : .anipickBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(isSelected ? Color.anipickPrimary : Color.gray7)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func retryState(message: String) -> some View {
        return VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray6)
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.anipickPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func animeInfoHeader() -> some View {
        return HStack(alignment: .top, spacing: 16) {
            if let urlString = state.coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 115, height: 105)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        coverPlaceholder()
                    }
                }
            } else {
                coverPlaceholder()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(state.animeTitle)
                    .textStyle(size: 16, color: .anipickBlack, weight: .bold)
                    .lineLimit(2)

                FlowTagLayout(spacing: 4) {
                    ForEach(state.genreNames, id: \.self) { name in
                        GenreTag(title: name)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private func coverPlaceholder() -> some View {
        return RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 115, height: 105)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
            )
    }

    private func spoilerBar() -> some View {
        return HStack {
            Spacer()
            HStack {
                Text("스포일러")
                    .textStyle(size: 14, color: .anipickPrimary)
                    .padding(.trailing, 6)
                Button {
                    store.send(.spoilerToggled)
                } label: {
                    Image(state.showsSpoilers ? .toggleEnable : .grayToggleOff)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func postCell(_ post: CommunityPost) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                CommunityProfileAvatar(imageURL: post.authorImageURL)

                Text(post.authorName)
                    .textStyle(size: 14, color: .anipickBlack)

                Spacer()

                Text(post.date)
                    .textStyle(size: 12, color: .gray6)
            }

            // 본문 + 오른쪽 첫 번째 첨부 사진
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    if !post.title.isEmpty {
                        Text(post.title)
                            .textStyle(size: 15, color: .anipickBlack, weight: .medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !post.content.isEmpty {
                        Text(post.content)
                            .textStyle(size: 14, color: .gray4)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let thumbnailURL = post.thumbnailURL {
                    thumbnail(thumbnailURL, imageCount: post.imageCount)
                }
            }

            // 조회 수는 늘 0으로 보인다 (레거시 그대로)
            HStack(spacing: 0) {
                reactionItem(icon: "eye", count: 0)
                Text("  |  ").textStyle(size: 13, color: .gray6)
                reactionItem(icon: "heart", count: post.likeCount)
                Text("  |  ").textStyle(size: 13, color: .gray6)
                reactionItem(icon: "bubble.left", count: post.commentCount)

                Spacer()

                if post.isSpoiler {
                    SpoilerTag()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.postTapped(post))
        }
        .cornerRadius(12)
    }

    private func reactionItem(icon: String, count: Int) -> some View {
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.gray6)
            Text("\(count)")
                .textStyle(size: 13, color: .gray6)
        }
    }

    private func thumbnail(_ url: URL, imageCount: Int) -> some View {
        return ZStack(alignment: .bottomTrailing) {
            ProtectedRemoteImage(url: url)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // 사진이 2장 이상이면 썸네일 외 나머지 장수를 표시
            if imageCount >= 2 {
                Text("+\(imageCount - 1)")
                    .textStyle(size: 11, color: .white, weight: .semibold)
                    .frame(minWidth: 24, minHeight: 24)
                    .padding(.horizontal, 2)
                    .background(Color.anipickBlack.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(6)
                    .accessibilityLabel("사진 \(imageCount)장")
            }
        }
    }
}
