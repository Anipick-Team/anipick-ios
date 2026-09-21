//
//  CommunityView.swift
//  AniPick
//

import SwiftUI

struct CommunityView: View {
    let animeId: Int
    let animeTitle: String
    let coverImageUrl: String?
    let genreNames: [String]

    @StateObject private var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager

    init(animeId: Int, animeTitle: String, coverImageUrl: String?, genreNames: [String]) {
        self.animeId = animeId
        self.animeTitle = animeTitle
        self.coverImageUrl = coverImageUrl
        self.genreNames = genreNames
        self._viewModel = StateObject(wrappedValue: CommunityViewModel(animeId: animeId))
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
                        spoilerBar()
                            .background(Color.white)
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts.filter { viewModel.isShowSpoiler || !$0.isSpoiler }) { post in
                                postCell(post)
                                    .onAppear {
                                        if post.id == viewModel.posts.last?.id {
                                            viewModel.fetchPosts()
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
                guard let seriesId = viewModel.seriesId else {
                    DLog("커뮤니티 글쓰기 이동 실패 - 게시판 정보 로딩 전")
                    return
                }
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
        .onAppear { viewModel.fetchPosts(reset: true) }
        .onChange(of: viewModel.selectedFilter) { _ in
            viewModel.fetchPosts(reset: true)
        }
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
                Circle()
                    .foregroundColor(.gray5)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(.animeThumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    )

                Text(post.authorName)
                    .customFontStyle(size: 14, color: .anipickBlack)

                Spacer()

                Text(post.date)
                    .customFontStyle(size: 12, color: .gray6)
            }

            // 본문
            if !post.title.isEmpty {
                Text(post.title)
                    .customFontStyle(size: 15, color: .anipickBlack, weight: .medium)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(post.content)
                .customFontStyle(size: 14, color: .anipickBlack)
                .foregroundColor(.gray8)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // 이미지 그리드
            if !post.imageUrls.isEmpty {
                imageGrid(post.imageUrls)
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
                    Text("스포일러")
                        .customFontStyle(size: 12, color: .anipickPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.anipickPrimary, lineWidth: 1)
                        )
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

    // MARK: - 이미지 그리드
    @ViewBuilder
    private func imageGrid(_ urls: [String]) -> some View {
        let maxDisplay = 5
        let displayCount = min(urls.count, maxDisplay)
        let overflow = urls.count - maxDisplay

        HStack(spacing: 4) {
            ForEach(0..<displayCount, id: \.self) { idx in
                ZStack {
                    if !urls[idx].isEmpty {
                        CommunityRemoteImage(urlString: urls[idx])
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundColor(.gray5)
                            .frame(width: 56, height: 56)
                    }

                    if idx == displayCount - 1 && overflow > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundColor(.black.opacity(0.35))
                            .frame(width: 56, height: 56)

                        Text("+\(overflow)")
                            .customFontStyle(size: 14, color: .white, weight: .semibold)
                    }
                }
            }
        }
    }

}

#Preview {
    CommunityView(
        animeId: 0,
        animeTitle: "진격의 거인",
        coverImageUrl: nil,
        genreNames: ["액션", "드라마", "판타지"]
    )
}
