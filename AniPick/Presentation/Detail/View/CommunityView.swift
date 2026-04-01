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

                Spacer().frame(height: 30)
                
                self.sectionDivder()
                    .padding(.horizontal, -20)
                
                Spacer().frame(height: 20)
                

                // MARK: - Scrollable Content
                ScrollView {
                    VStack(spacing: 0) {
                        animeInfoHeader()
                            .background(Color.white)
                        filterBar()
                            .background(Color.white)
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
                                postCell(post)
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
                // TODO: 글쓰기 화면으로 이동
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
        HStack(alignment: .center, spacing: 16) {
            // 커버 이미지
            if let urlString = coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
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
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    @ViewBuilder
    private func coverPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 88, height: 88)
            .overlay(
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            )
    }

    // MARK: - 필터 바
    @ViewBuilder
    private func filterBar() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(CommunityFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .customFontStyle(
                                size: 14,
                                color: viewModel.selectedFilter == filter ? .white : .anipickBlack
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedFilter == filter
                                    ? Color.anipickPrimary
                                    : Color.clear
                            )
                            .cornerRadius(20)
                    }
                }
                Spacer()
            }

            HStack {
                Spacer()
                Text("스포일러")
                    .customFontStyle(size: 14, color: .anipickPrimary)
                    .padding(.trailing, 6)
                Button {
                    viewModel.isShowSpoiler.toggle()
                } label: {
                    Image(viewModel.isShowSpoiler ? .toggleEnable : .grayToggleOff)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
            Text(post.content)
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // 이미지 그리드
            if !post.imageUrls.isEmpty {
                imageGrid(post.imageUrls)
            }

            // 반응 + 스포일러 태그
            HStack(spacing: 0) {
                reactionItem(icon: "heart", count: post.likeCount)
                Text("  |  ").customFontStyle(size: 13, color: .gray6)
                reactionItem(icon: "heart", count: post.dislikeCount)
                Text("  |  ").customFontStyle(size: 13, color: .gray6)
                reactionItem(icon: "heart", count: post.commentCount)

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
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(.gray5)
                        .frame(width: 56, height: 56)

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
