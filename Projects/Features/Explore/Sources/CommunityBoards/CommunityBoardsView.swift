import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `ExploreCommunityView`와 같은 배치
struct CommunityBoardsView: View {
    @State private var store: Store<CommunityBoardsReducer>
    /// 정렬 메뉴 위치 (레이아웃 값이라 View가 들고 있다, 레거시와 같음)
    @State private var sortButtonFrame: CGRect = .zero
    private let dropdownWidth: CGFloat = 90

    init(state: CommunityBoardsReducer.State, reducer: CommunityBoardsReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

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
                        content()
                    }
                }
            }

            if store.state.isSortMenuPresented {
                sortMenu()
            }
        }
        .coordinateSpace(name: "communityZStack")
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.backgroundTapped)
        }
        .task {
            store.send(.appeared)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        if store.state.isLoading && store.state.items.isEmpty {
            ProgressView()
                .padding(.top, 40)
        } else if let errorMessage = store.state.errorMessage, store.state.items.isEmpty {
            VStack(spacing: 12) {
                Text(errorMessage)
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
        } else if store.state.items.isEmpty {
            Text("검색조건에 맞는 결과가 없어요.\n다른 조건으로 검색해보세요.")
                .font(.system(size: 14))
                .foregroundColor(.gray6)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
        } else {
            ForEach(store.state.items, id: \.self) { item in
                cell(item)
                    .onAppear {
                        store.send(.itemAppeared(item))
                    }
            }
        }
    }

    private func searchBar() -> some View {
        return HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if store.state.searchText.isEmpty {
                    Text("검색어 입력")
                        .font(.system(size: 15))
                        .foregroundColor(.gray6)
                        .allowsHitTesting(false)
                }
                TextField(
                    "",
                    text: Binding(
                        get: { store.state.searchText },
                        set: { store.send(.searchTextChanged($0)) }
                    )
                )
                .font(.system(size: 15))
                .foregroundColor(.anipickBlack)
            }

            Spacer()

            Image(.searchIconsGray)
                .resizable()
                .frame(width: 20, height: 20)

            Button {
                store.send(.clearSearchTapped)
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

    private func sortButton() -> some View {
        return Button {
            store.send(.sortButtonTapped)
        } label: {
            HStack(spacing: 4) {
                Text(store.state.sortTitle)
                    .textStyle(size: 14, color: .gray8)
                Image(systemName: store.state.isSortMenuPresented ? "chevron.up" : "chevron.down")
                    .resizable()
                    .frame(width: 9, height: 6)
                    .foregroundColor(.gray8)
            }
        }
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .named("communityZStack"))
        } action: {
            sortButtonFrame = $0
        }
    }

    private func sortMenu() -> some View {
        let options = CommunityBoardsReducer.sortOptions
        return VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    store.send(.sortSelected(option))
                } label: {
                    Text(option)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.anipickBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 13)
                }
                if option != options.last {
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
            y: sortButtonFrame.maxY + 6 + CGFloat(options.count) * 32
        )
        .zIndex(2)
    }

    private func cell(_ item: CommunityBoardsReducer.Item) -> some View {
        return HStack(alignment: .center, spacing: 20) {
            if let urlString = item.board.coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 116, height: 116)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        placeholder()
                    }
                }
            } else {
                placeholder()
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
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.itemTapped(item))
        }
    }

    private func placeholder() -> some View {
        return RoundedRectangle(cornerRadius: 10)
            .foregroundColor(.gray5)
            .frame(width: 116, height: 116)
    }
}
