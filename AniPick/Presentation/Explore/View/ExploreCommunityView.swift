//
//  ExploreCommunityView.swift
//  AniPick
//

import SwiftUI

struct ExploreCommunityView: View {
    @State private var searchText: String = ""
    @State private var isShowSortOption: Bool = false
    @State private var selectedSort: String = "인기순"
    @State private var sortButtonFrame: CGRect = .zero

    private let sortOptions = ["인기순", "최신순"]

    // TODO: API 연결 시 ViewModel로 분리
    private let dummyItems: [CommunityAnimeItem] = (0..<8).map {
        CommunityAnimeItem(id: $0, title: "애니메이션 제목", tag: "text", coverImageUrl: nil)
    }

    private let dropdownWidth: CGFloat = 160

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                searchBar()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                HStack {
                    Spacer()
                    sortButton()
                        .padding(.trailing, 20)
                }
                .padding(.bottom, 8)

                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .foregroundColor(.gray7)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(dummyItems) { item in
                            communityAnimeCell(item: item)
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }

            if isShowSortOption {
                VStack(spacing: 0) {
                    ForEach(sortOptions, id: \.self) { option in
                        Button {
                            selectedSort = option
                            isShowSortOption = false
                        } label: {
                            Text(option)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.anipickBlack)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        }
                        if option != sortOptions.last {
                            Rectangle()
                                .frame(maxWidth: .infinity)
                                .frame(height: 1)
                                .foregroundColor(.gray7)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .frame(width: dropdownWidth)
                .position(
                    x: sortButtonFrame.maxX - dropdownWidth / 2,
                    y: sortButtonFrame.maxY + 8 + (CGFloat(sortOptions.count) * 61 / 2)
                )
                .zIndex(2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isShowSortOption { isShowSortOption = false }
        }
    }

    @ViewBuilder
    private func searchBar() -> some View {
        HStack(spacing: 12) {
            TextField("검색어 입력", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.anipickBlack)

            Spacer()

            Image(.searchIconsGray)
                .resizable()
                .frame(width: 20, height: 20)

            Button {
                searchText = ""
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(.gray6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray7)
        .cornerRadius(8)
    }

    @ViewBuilder
    private func sortButton() -> some View {
        Button {
            isShowSortOption.toggle()
        } label: {
            HStack(spacing: 4) {
                Text(selectedSort)
                    .customFontStyle(size: 14, color: .gray8)
                Image(systemName: isShowSortOption ? "chevron.up" : "chevron.down")
                    .resizable()
                    .frame(width: 9, height: 6)
                    .foregroundColor(.gray8)
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { sortButtonFrame = proxy.frame(in: .global) }
                    .onChange(of: isShowSortOption) { _ in
                        sortButtonFrame = proxy.frame(in: .global)
                    }
            }
        )
    }

    @ViewBuilder
    private func communityAnimeCell(item: CommunityAnimeItem) -> some View {
        HStack(alignment: .center, spacing: 16) {
            if let urlString = item.coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        placeholderImage()
                    }
                }
            } else {
                placeholderImage()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .customFontStyle(size: 15, color: .anipickBlack, weight: .semibold)
                    .lineLimit(1)

                Text(item.tag)
                    .customFontStyle(size: 12, color: .anipickPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.anipickPrimary.opacity(0.12))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    @ViewBuilder
    private func placeholderImage() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundColor(.gray5)
            .frame(width: 72, height: 72)
    }
}

struct CommunityAnimeItem: Identifiable {
    let id: Int
    let title: String
    let tag: String
    let coverImageUrl: String?
}
