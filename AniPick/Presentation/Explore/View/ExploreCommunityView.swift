//
//  ExploreCommunityView.swift
//  AniPick
//

import SwiftUI

struct ExploreCommunityView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var viewModel = CommunityExploreViewModel()
    @State private var searchText: String = ""
    @State private var isShowSortOption: Bool = false
    @State private var selectedSort: String = "인기순"
    @State private var sortButtonFrame: CGRect = .zero

    private let sortOptions = ["인기순", "최신순"]

    private let dropdownWidth: CGFloat = 90

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                searchBar()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .foregroundColor(.gray7)

                HStack {
                    Spacer()
                    sortButton()
                        .padding(.trailing, 20)
                }
                .padding(.vertical, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.items) { item in
                            communityAnimeCell(item: item)
                                .onAppear {
                                    if item.id == viewModel.items.last?.id {
                                        viewModel.fetch()
                                    }
                                }
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
                            viewModel.setSort(option == "인기순" ? "popular" : "latest")
                        } label: {
                            Text(option)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.anipickBlack)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 13)
                        }
                        if option != sortOptions.last {
                            Rectangle()
                                .frame(maxWidth: .infinity)
                                .frame(height: 1)
                                .foregroundColor(.gray7)
                                .padding(.horizontal, 15)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .frame(width: dropdownWidth)
                .position(
                    x: sortButtonFrame.maxX - dropdownWidth / 2,
                    y: sortButtonFrame.maxY + 6 + CGFloat(sortOptions.count) * 32
                )
                .zIndex(2)
            }
        }
        .coordinateSpace(name: "communityZStack")
        .contentShape(Rectangle())
        .onTapGesture {
            if isShowSortOption { isShowSortOption = false }
        }
        .task { viewModel.fetch(reset: true) }
        .onChange(of: searchText) { _ in viewModel.search(keyword: searchText) }
    }

    @ViewBuilder
    private func searchBar() -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("검색어 입력")
                        .font(.system(size: 15))
                        .foregroundColor(.gray6)
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.anipickBlack)
            }

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
                    .onAppear { sortButtonFrame = proxy.frame(in: .named("communityZStack")) }
                    .onChange(of: isShowSortOption) { _ in
                        sortButtonFrame = proxy.frame(in: .named("communityZStack"))
                    }
            }
        )
    }

    @ViewBuilder
    private func communityAnimeCell(item: CommunityAnimeItem) -> some View {
        HStack(alignment: .center, spacing: 20) {
            if let urlString = item.coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 116, height: 116)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        placeholderImage()
                    }
                }
            } else {
                placeholderImage()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.anipickBlack)
                    .lineLimit(2)

                Text(item.tag)
                    .font(.system(size: 12))
                    .foregroundColor(.anipickPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.anipickPrimary.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.anipickPrimary.opacity(0.4), lineWidth: 1)
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            navigationManager.push(
                route: .community(
                    animeId: item.id,
                    animeTitle: item.title,
                    coverImageUrl: item.coverImageUrl,
                    genreNames: []
                )
            )
        }
    }

    @ViewBuilder
    private func placeholderImage() -> some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundColor(.gray5)
            .frame(width: 116, height: 116)
    }
}

struct CommunityAnimeItem: Identifiable {
    let id: Int
    let title: String
    let tag: String
    let coverImageUrl: String?
}

final class CommunityExploreViewModel: ObservableObject {
    @Published var items: [CommunityAnimeItem] = []
    private var lastId: Int?
    private var lastValue: String?
    private var hasNextPage = true
    private var isLoading = false
    private var keyword = ""
    private var sort = "popular"

    func setSort(_ sort: String) {
        self.sort = sort
        fetch(reset: true)
    }

    func search(keyword: String) {
        self.keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await MainActor.run { self.fetch(reset: true) }
        }
    }

    func fetch(reset: Bool = false) {
        guard !isLoading, reset || hasNextPage else { return }
        if reset {
            lastId = nil
            lastValue = nil
            hasNextPage = true
        }
        isLoading = true

        Task {
            do {
                let response = try await CommunityAPIService.shared.exploreBoards(
                    sort: sort,
                    keyword: keyword.isEmpty ? nil : keyword,
                    lastValue: lastValue,
                    lastId: lastId
                )
                let boards = response.result?.boards ?? []
                let newItems = boards.map {
                    CommunityAnimeItem(
                        id: $0.seriesId,
                        title: $0.title ?? "제목 없음",
                        tag: $0.genres?.first?.name ?? "커뮤니티",
                        coverImageUrl: $0.coverImageUrl
                    )
                }
                let cursor = response.result?.cursor
                DLog("커뮤니티 탐색 조회 성공 - sort: \(sort), keyword: \(keyword), count: \(newItems.count), cursor: \(String(describing: cursor))")
                await MainActor.run {
                    self.items = reset ? newItems : self.items + newItems
                    self.lastId = cursor?.lastId
                    self.lastValue = cursor?.lastValue
                    self.hasNextPage = newItems.isEmpty == false && cursor?.lastId != nil
                    self.isLoading = false
                }
            } catch {
                DLog("커뮤니티 탐색 조회 실패 - error: \(error.localizedDescription)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
