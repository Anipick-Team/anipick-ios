import DesignSystem
import ExploreClientInterface
import MVICore
import SwiftUI

/// 레거시 `ExploreView`와 같은 배치. 필터 줄 숨김(스크롤 차이 30 초과, 0.2초 잠금)은 레이아웃 상태라 View가 들고 있다.
struct ExploreView<Community: View>: View {
    @State private var store: Store<ExploreReducer>
    @State private var showFilterBar = true
    @State private var currentScrollOffset: CGFloat = 0
    @State private var filterBarLocked = false
    @State private var sheetHeight: CGFloat = 400
    private let community: () -> Community
    private let pendingFilterUpdates: () -> AsyncStream<Void>
    private let scrollThreshold: CGFloat = 30
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(
        state: ExploreReducer.State,
        reducer: ExploreReducer,
        pendingFilterUpdates: @escaping () -> AsyncStream<Void>,
        @ViewBuilder community: @escaping () -> Community
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.pendingFilterUpdates = pendingFilterUpdates
        self.community = community
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                header()

                if store.state.mainTab == .anime {
                    animeTab()
                } else {
                    community()
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { store.state.isFilterSheetPresented },
                    set: { store.send(.filterSheetPresentedChanged($0)) }
                )
            ) {
                filterSheet()
                    .id(store.state.filterTab)
                    .presentationDetents([.height(sheetHeight)])
            }
            .background(Color.white)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                store.send(.appeared)
            }
            .task {
                for await _ in pendingFilterUpdates() {
                    store.send(.pendingFilterChanged)
                }
            }

            if store.state.isSortMenuPresented && store.state.mainTab == .anime {
                sortMenu()
                    .padding(.trailing, 20)
                    .offset(y: 160)
                    .zIndex(2)
                    .animation(.easeInOut, value: store.state.isSortMenuPresented)
            }
        }
        // 두 하위 탭 모두 메인 탭 안이라 하단 탭 바를 유지한다 (레거시 그대로)
        .toolbar(.visible, for: .tabBar)
    }

    // MARK: - 머리

    private func header() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(.aniPickLogoGreen)
                    .resizable()
                    .frame(width: 110, height: 22)

                Spacer()

                Button {
                    store.send(.searchTapped)
                } label: {
                    Image(.searchIconsGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)

            mainTabBar()

            if showFilterBar {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.gray5)

                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 9)
                    .background(.gray7)
            }
        }
    }

    private func mainTabBar() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ExploreReducer.MainTab.allCases, id: \.self) { tab in
                    let isSelected = store.state.mainTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = store.send(.mainTabSelected(tab))
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .anipickBlack : .gray6)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)

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

    // MARK: - 작품 탐색

    @ViewBuilder
    private func animeTab() -> some View {
        if showFilterBar {
            Spacer().frame(height: 16)

            HStack(spacing: 0) {
                filterChip(.yearQuarter)
                    .padding(.trailing, 8)
                filterChip(.genre)
                    .padding(.trailing, 8)
                filterChip(.type)
            }
            .padding(.horizontal, showFilterBar ? 20 : 0)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }

        if !store.state.tags.isEmpty {
            tagRow()
        }

        HStack(spacing: 0) {
            Spacer()
            Button {
                store.send(.sortButtonTapped)
            } label: {
                Text(store.state.sort.title)
                    .textStyle(size: 14, color: .gray8)
                    .padding(.trailing, 20)
            }
        }
        .padding(.bottom, 20)
        .padding(.top, 8)

        ScrollView(showsIndicators: false) {
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                        scrolled(to: newValue)
                    }
            }
            .frame(height: 0)

            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(store.state.items, id: \.animeId) { item in
                    Button {
                        store.send(.itemTapped(item))
                    } label: {
                        TitledCoverImage(
                            url: item.coverImageUrl, width: nil, height: 162, title: item.title)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        store.send(.itemAppeared(item))
                    }
                }
            }
        }
        .coordinateSpace(name: "explore")
        .padding(.horizontal, 20)
    }

    private func scrolled(to offset: CGFloat) {
        let diff = offset - currentScrollOffset
        currentScrollOffset = offset
        guard !filterBarLocked, abs(diff) > scrollThreshold else {
            return
        }
        let show = diff > 0
        guard show != showFilterBar else {
            return
        }
        filterBarLocked = true
        withAnimation(.easeInOut(duration: 0.05)) { showFilterBar = show }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            filterBarLocked = false
        }
    }

    private func filterChip(_ tab: ExploreReducer.FilterTab) -> some View {
        let isSelected = store.state.hasTag(tab)
        return VStack(spacing: 0) {
            Button {
                store.send(.filterChipTapped(tab))
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text(tab.rawValue)
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? .anipickSecondary : .textBlack)
                        .padding(.trailing, 10)

                    Image(isSelected ? .chevronDownBlue : .chevronDownGray)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(isSelected ? .anipickSecondary : .gray5, lineWidth: 1)
                )
                .foregroundStyle(.anipickBlack)
            }
        }
    }

    private func tagRow() -> some View {
        return VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray5)

            Spacer().frame(height: 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(store.state.tags, id: \.self) { tag in
                        HStack(spacing: 0) {
                            Text(tag.title)
                                .padding(.trailing, 4)
                                .textStyle(size: 14, color: .anipickPrimary)

                            Button {
                                store.send(.tagRemoved(tag))
                            } label: {
                                Image(.xButtonGreen)
                                    .resizable()
                                    .frame(width: 15, height: 15)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.anipickPrimary.opacity(0.2))
                        .cornerRadius(32)
                    }
                    .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func sortMenu() -> some View {
        return VStack(spacing: 0) {
            ForEach(ExploreReducer.Sort.allCases, id: \.self) { sort in
                Button {
                    store.send(.sortSelected(sort))
                } label: {
                    Text(sort.title)
                        .textStyle(size: 14, color: .anipickBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white)
                        .padding(.vertical, 13)
                }
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundColor(.gray7)
                    .padding(.horizontal, 15)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(width: 91)
    }

    // MARK: - 필터 시트

    private func filterSheet() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach([ExploreReducer.FilterTab.yearQuarter, .genre, .type], id: \.self) { tab in
                    Button {
                        store.send(.filterTabSelected(tab))
                    } label: {
                        Text(tab.rawValue)
                            .padding(.horizontal, 12)
                            .font(.system(size: 16))
                            .foregroundStyle(
                                store.state.filterTab == tab ? .anipickBlack : .textGray)
                    }
                }

                Spacer()

                Button {
                    store.send(.filterCloseTapped)
                } label: {
                    Image(.xButton)
                        .frame(width: 12, height: 12)
                }
            }
            .foregroundStyle(.textBlack)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray7)

            switch store.state.filterTab {
            case .yearQuarter:
                yearQuarterPickers()
            case .genre:
                genrePicker()
            case .type:
                typePicker()
            case .season:
                EmptyView()
            }

            Spacer()

            HStack(spacing: 0) {
                Spacer()

                Button {
                    store.send(.filterResetTapped)
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }

                Spacer().frame(width: 16)

                Button {
                    store.send(.filterDoneTapped)
                } label: {
                    Text("완료")
                        .frame(width: 60, height: 30)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                        .background(.anipickPrimary)
                        .cornerRadius(4)
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 20)
        .background(.white)
        .onAppear {
            store.send(.filterSheetAppeared)
        }
    }

    private func yearQuarterPickers() -> some View {
        return HStack(spacing: 0) {
            Picker(
                "",
                selection: Binding(
                    get: { store.state.pickerYear },
                    set: { store.send(.pickerYearChanged($0)) }
                )
            ) {
                ForEach(store.state.currentOptions, id: \.self) {
                    Text($0)
                        .textStyle(size: 14, color: .anipickBlack)
                }
            }
            .pickerStyle(.wheel)

            Picker(
                "",
                selection: Binding(
                    get: { store.state.pickerSeason },
                    set: { store.send(.pickerSeasonChanged($0)) }
                )
            ) {
                ForEach(ExploreReducer.quarters, id: \.self) {
                    Text($0)
                        .textStyle(size: 14, color: .anipickBlack)
                }
            }
            .pickerStyle(.wheel)
        }
    }

    private func genrePicker() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                Button {
                    store.send(.matchAllGenresTapped)
                } label: {
                    Text("모든 조건 일치")
                        .textStyle(size: 14, color: .anipickBlack)
                        .padding(.trailing, 4)
                    Image(store.state.matchesAllGenres ? .grayToggleOn : .grayToggleOff)
                        .resizable()
                        .frame(width: 40, height: 24)
                }
            }
            .padding(.bottom, 12)
            .padding(.trailing, 8)

            ScrollView(showsIndicators: false) {
                FlowTagLayout {
                    ForEach(store.state.currentOptions, id: \.self) { genre in
                        let isSelected = store.state.highlightedGenres.contains(genre)
                        Button {
                            store.send(.genreToggled(genre))
                        } label: {
                            optionChip(genre, isSelected: isSelected)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.white)
    }

    private func typePicker() -> some View {
        return ScrollView(showsIndicators: false) {
            FlowTagLayout {
                ForEach(store.state.currentOptions, id: \.self) { type in
                    Button {
                        store.send(.typeSelected(type))
                    } label: {
                        optionChip(type, isSelected: store.state.pickerType == type)
                    }
                }
            }
        }
        .padding(20)
    }

    private func optionChip(_ title: String, isSelected: Bool) -> some View {
        return Text(title)
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .anipickSecondary : .textBlack)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .anipickSecondary : .gray6)
            )
    }
}
