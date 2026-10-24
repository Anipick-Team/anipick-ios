//
//  CommunityView.swift
//  AniPick
//

import SwiftUI

struct CommunityView: View {
    let seriesId: Int
    let animeTitle: String
    let coverImageUrl: String?
    let genreNames: [String]

    @StateObject private var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager

    init(seriesId: Int, animeTitle: String, coverImageUrl: String?, genreNames: [String]) {
        self.seriesId = seriesId
        self.animeTitle = animeTitle
        self.coverImageUrl = coverImageUrl
        self.genreNames = genreNames
        self._viewModel = StateObject(wrappedValue: CommunityViewModel(seriesId: seriesId))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {

                // MARK: - Navigation Header
                NavigationBackButtonView(title: "커뮤니티") {
                    dismiss()
                }

                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        animeInfoHeader()
                            .background(Color.white)
                        filterBar()
                            .background(Color.white)
                        spoilerBar()
                            .background(Color.white)
                        LazyVStack(spacing: 12) {
                            if viewModel.isLoading && viewModel.posts.isEmpty {
                                ProgressView()
                                    .padding(.top, 40)
                            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                                retryState(message: errorMessage) {
                                    viewModel.fetchPosts(reset: true)
                                }
                            } else if viewModel.posts.isEmpty {
                                Text("아직 작성된 게시글이 없어요.\n첫 글을 남겨보세요.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray6)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 40)
                            } else {
                                ForEach(viewModel.posts.filter { viewModel.isShowSpoiler || !$0.isSpoiler }) { post in
                                    postCell(post)
                                        .onAppear {
                                            if post.id == viewModel.posts.last?.id {
                                                viewModel.fetchPosts()
                                            }
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
            // MARK: - FAB
            Button {
                navigationManager.push(route: .communityWrite(seriesId: seriesId, animeTitle: animeTitle))
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
        // 탐색의 커뮤니티 목록에서는 탭을 유지하고, 게시판에 진입한 뒤에는 숨깁니다.
        .toolbar(.hidden, for: .tabBar)
        .onAppear { viewModel.fetchPosts(reset: true) }
        .onChange(of: viewModel.selectedFilter) { _ in
            viewModel.fetchPosts(reset: true)
        }
    }

    @ViewBuilder
    private func filterBar() -> some View {
        HStack(spacing: 6) {
            ForEach(CommunityFilter.allCases, id: \.self) { filter in
                Button {
                    viewModel.selectedFilter = filter
                    DLog("커뮤니티 필터 선택 - \(filter.rawValue)")
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: viewModel.selectedFilter == filter ? .semibold : .regular))
                        .foregroundColor(viewModel.selectedFilter == filter ? .white : .anipickBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(viewModel.selectedFilter == filter ? Color.anipickPrimary : Color.gray7)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func retryState(message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray6)
            Button("다시 시도", action: retry)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.anipickPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }


    // MARK: - 애니 정보 헤더
    @ViewBuilder
    private func animeInfoHeader() -> some View {
        HStack(alignment: .top, spacing: 16) {
            // 커버 이미지
            if let urlString = coverImageUrl, let url = URL(string: urlString) {
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
                Text(animeTitle)
                    .customFontStyle(size: 16, color: .anipickBlack, weight: .bold)
                    .lineLimit(2)

                FlowLayout(spacing: 4) {
                    ForEach(genreNames, id: \.self) { name in
                        GerneTagComponents(title: name)
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

    @ViewBuilder
    private func coverPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 115, height: 105)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
            )
    }

    // MARK: - 스포일러 표시 설정
    @ViewBuilder
    private func spoilerBar() -> some View {
        HStack {
            Spacer()
            HStack {
                Text("스포일러")
                    .customFontStyle(size: 14, color: .anipickPrimary)
                    .padding(.trailing, 6)
                Button {
                    viewModel.isShowSpoiler.toggle()
                } label: {
                    Image(viewModel.isShowSpoiler ? .toggleEnable : .grayToggleOff)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - 포스트 셀
    @ViewBuilder
    private func postCell(_ post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // 작성자 정보
            HStack(alignment: .center, spacing: 8) {
                CommunityProfileAvatar(imageURL: post.authorImageUrl)

                Text(post.authorName)
                    .customFontStyle(size: 14, color: .anipickBlack)

                Spacer()

                Text(post.date)
                    .customFontStyle(size: 12, color: .gray6)
            }

            // 본문 + 우측 첫 번째 첨부 사진
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    if !post.title.isEmpty {
                        Text(post.title)
                            .customFontStyle(size: 15, color: .anipickBlack, weight: .medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(post.content)
                        .customFontStyle(size: 14, color: .gray4)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let firstImageUrl = post.imageUrls.first {
                    postThumbnail(firstImageUrl, imageCount: post.imageCount)
                }
            }

            // 반응 + 스포일러 태그
            HStack(spacing: 0) {
                reactionItem(icon: "eye", count: 0)
                Text("  |  ").customFontStyle(size: 13, color: .gray6)
                reactionItem(icon: "heart", count: post.likeCount)
                Text("  |  ").customFontStyle(size: 13, color: .gray6)
                reactionItem(icon: "bubble.left", count: post.commentCount)

                Spacer()

                if post.isSpoiler {
                    SpoilerTagView()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            navigationManager.push(route: .communityDetail(postId: post.id))
        }
        .cornerRadius(12)
    }

    @ViewBuilder
    private func reactionItem(icon: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.gray6)
            Text("\(count)")
                .customFontStyle(size: 13, color: .gray6)
        }
    }

    // MARK: - 썸네일
    @ViewBuilder
    private func postThumbnail(_ urlString: String, imageCount: Int) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if urlString.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.gray5)
                    .frame(width: 96, height: 96)
            } else {
                CommunityRemoteImage(urlString: urlString)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 사진이 2장 이상이면 썸네일 외 나머지 장수를 표시
            if imageCount >= 2 {
                Text("+\(imageCount - 1)")
                    .customFontStyle(size: 11, color: .white, weight: .semibold)
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

#Preview {
    CommunityView(
        seriesId: 0,
        animeTitle: "진격의 거인",
        coverImageUrl: nil,
        genreNames: ["액션", "드라마", "판타지"]
    )
}
