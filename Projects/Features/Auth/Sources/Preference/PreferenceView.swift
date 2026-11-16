import DesignSystem
import ExploreClientInterface
import MVICore
import SwiftUI
import UIKit

/// 레거시 `PreferenceSelectionView`와 같은 배치.
/// 헤더 숨김(스크롤 차이 30 초과, 0.2초 잠금)·검색창 포커스·시트 높이는 레이아웃 상태라 View가 들고 있다 (레거시와 같음).
struct PreferenceView: View {
    @State private var store: Store<PreferenceReducer>
    @State private var isHeaderHidden = false
    @State private var currentScrollOffset: CGFloat = 0
    @State private var filterBarLocked = false
    @State private var sheetHeight: CGFloat = 400
    @FocusState private var isSearchFocused: Bool
    private let scrollThreshold: CGFloat = 30

    init(state: PreferenceReducer.State, reducer: PreferenceReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 34)

            Text("좋아하는 애니메이션을 선택하면\n취향에 맞는 작품을 추천할게요")
                .textStyle(size: 20, color: .anipickBlack, weight: .semibold)
                .padding(.bottom, 8)

            Text("좋아하는 애니메이션을 골라 주세요.")
                .textStyle(size: 14, color: .anipickSecondary)

            Spacer().frame(height: 40)

            if !isHeaderHidden {
                header()
            }

            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                            scrolled(to: newValue)
                        }
                }
                .frame(height: 0)

                LazyVStack(spacing: 0) {
                    ForEach(store.state.animes, id: \.self) { anime in
                        let animeId = anime.animeId ?? 0
                        cell(anime)
                            .onAppear {
                                store.send(.itemAppeared(anime))
                            }

                        if store.state.openedRatingIds.contains(animeId) {
                            RatingInputRow { rating in
                                store.send(.ratingSubmitted(animeId: animeId, rating: rating))
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "scroll")
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isSearchFocused {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .foregroundStyle(.gray5)
                        .padding(.horizontal, -20)

                    Spacer().frame(height: 20)

                    // 늘 활성
                    PrimaryButton("완료") {
                        store.send(.doneTapped)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 20)
                }
                .background(Color.white)
            }
        }
        .background(Color.white)
        .sheet(
            isPresented: Binding(
                get: { store.state.isFilterSheetPresented },
                set: { store.send(.filterSheetPresentedChanged($0)) }
            )
        ) {
            filterSheet()
                .presentationDetents([.height(sheetHeight)])
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    sheetHeight = $0
                }
        }
        .onAppear {
            store.send(.appeared)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: isSearchFocused) { _, focused in
            if !focused {
                store.send(.searchRequested)
            }
        }
    }

    /// 아래로 내리면 헤더를 숨기고 올리면 보인다 (PS13)
    private func scrolled(to offset: CGFloat) {
        let diff = offset - currentScrollOffset
        currentScrollOffset = offset
        guard !filterBarLocked, abs(diff) > scrollThreshold else {
            return
        }
        let hide = diff < 0
        guard hide != isHeaderHidden else {
            return
        }
        filterBarLocked = true
        withAnimation(.easeInOut(duration: 0.05)) { isHeaderHidden = hide }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            filterBarLocked = false
        }
    }

    // MARK: - 헤더

    private func header() -> some View {
        let ratedCount = store.state.ratings.count
        return VStack(alignment: .leading, spacing: 0) {
            Text("평가한 작품 \(ratedCount)")
                .textStyle(size: 14, color: ratedCount > 0 ? .point : .gray6)

            Spacer().frame(height: 16)

            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)

                TextField(
                    "",
                    text: Binding(
                        get: { store.state.query },
                        set: { store.send(.queryChanged($0)) }
                    ),
                    prompt: Text("검색")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textGray)
                )
                .focused($isSearchFocused)
                .onSubmit {
                    store.send(.searchRequested)
                }
                .padding(.horizontal, 4)
                .background(Color.gray5)
                .foregroundColor(.anipickBlack)

                Spacer()

                Button {
                    store.send(.clearSearchTapped)
                } label: {
                    Image(.allClearButton)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 11)
            .background(Color.gray5)
            .cornerRadius(8)

            Spacer().frame(height: 16)

            HStack(spacing: 0) {
                filterChip(
                    store.state.selectedYear.isEmpty ? "년도" : store.state.selectedYear,
                    isSelected: !store.state.selectedYear.isEmpty, tab: .yearQuarter
                )
                .padding(.trailing, 8)

                filterChip(
                    store.state.selectedQuarter.isEmpty ? "분기" : "\(store.state.selectedQuarter)분기",
                    isSelected: !store.state.selectedQuarter.isEmpty, tab: .yearQuarter
                )
                .padding(.trailing, 8)

                filterChip(
                    store.state.selectedGenre.isEmpty ? "장르" : store.state.selectedGenre,
                    isSelected: !store.state.selectedGenre.isEmpty, tab: .genre
                )
            }

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray5)
                .padding(.horizontal, -20)
                .padding(.vertical, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, tab: PreferenceReducer.FilterTab)
        -> some View
    {
        return Button {
            store.send(.filterChipTapped(tab))
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Text(title)
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

    // MARK: - 칸

    private func cell(_ anime: OnboardingAnime) -> some View {
        let animeId = anime.animeId ?? 0
        let rating = store.state.rating(of: animeId)
        return VStack(spacing: 0) {
            Button {
                store.send(.animeTapped(animeId))
            } label: {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                if let url = anime.coverImageUrl {
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            thumbnail(image)
                                        case .empty, .failure:
                                            thumbnail(Image(.animeThumbnail))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.trailing, 20)

                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(anime.title ?? "--")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.textBlack)
                                        .padding(.bottom, 4)
                                        .padding(.top, 4)
                                        .padding(.trailing, 2)

                                    Spacer()

                                    if rating != nil {
                                        Button {
                                            store.send(.ratingCancelTapped(animeId))
                                        } label: {
                                            Text("평가취소")
                                                .frame(width: 56, height: 27)
                                                .textStyle(size: 12, color: .background)
                                                .background(Color.anipickPrimary)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding(.bottom, 4)

                                if let genres = anime.genres {
                                    Text(genres.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.textGray)
                                }

                                Spacer()

                                if let rating {
                                    StarRatingInput(
                                        rating: rating, fontSize: 13, fontColor: .point,
                                        starSize: 18
                                    ) { star in
                                        store.send(.ratingChanged(animeId: animeId, rating: star))
                                    }
                                    .padding(.bottom, 4)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray7, lineWidth: 1)
                            .background(Color.white.cornerRadius(8))
                            .frame(maxWidth: .infinity)
                    )
                }
            }
        }
    }

    private func thumbnail(_ image: Image) -> some View {
        return
            image
            .resizable()
            .scaledToFill()
            .frame(width: 133, height: 89)
            .clipped()
    }

    // MARK: - 필터 시트

    private func filterSheet() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PreferenceReducer.FilterTab.allCases, id: \.self) { tab in
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

            if store.state.filterTab == .yearQuarter {
                HStack(spacing: 0) {
                    Picker(
                        "",
                        selection: Binding(
                            get: { store.state.selectedYear },
                            set: { store.send(.yearChanged($0)) }
                        )
                    ) {
                        ForEach(store.state.seasonYears, id: \.self) {
                            Text($0)
                                .textStyle(size: 18, color: .anipickSecondary)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker(
                        "",
                        selection: Binding(
                            get: { store.state.selectedQuarter },
                            set: { store.send(.quarterChanged($0)) }
                        )
                    ) {
                        ForEach(PreferenceReducer.quarters, id: \.self) {
                            Text($0)
                                .textStyle(size: 18, color: .anipickSecondary)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    FlowTagLayout {
                        ForEach(store.state.genres.map(\.name), id: \.self) { name in
                            let isSelected = store.state.selectedGenre == name
                            Button {
                                store.send(.genreSelected(name))
                            } label: {
                                Text(name)
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
                    }
                }
                .padding(20)
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
    }
}

/// 별점 고르기 + "평가하기" (레거시 `StarRatingView`). 0점이어도 누르면 0으로 저장한다
struct RatingInputRow: View {
    @State private var rating: Double = 0
    let onSubmit: (Double) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StarRatingInput(rating: rating, fontSize: 16, fontColor: .point, starSize: 27) {
                    rating = $0
                }

                Spacer()

                Button {
                    onSubmit(rating)
                } label: {
                    Text("평가하기")
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .frame(width: 74)
                .background(rating > 0 ? .anipickPrimary : .gray6)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.gray7)
            .cornerRadius(4)
        }
        .background(Color.white)
        .frame(height: 68)
    }
}
