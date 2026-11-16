import DesignSystem
import MVICore
import RankingClientInterface
import SwiftUI

/// 레거시 `RankingView`와 같은 배치
struct RankingView: View {
    @State private var store: Store<RankingReducer>
    private let sheetHeight: CGFloat = 300

    init(state: RankingReducer.State, reducer: RankingReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(spacing: 0) {
            header()

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

            filterBar()

            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray7)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(store.state.items, id: \.self) { item in
                        rankingCell(item)
                            .padding(.vertical, 16)
                            .onAppear {
                                store.send(.itemAppeared(item))
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isGenreSheetPresented },
                set: { store.send(.genreSheetPresentedChanged($0)) }
            )
        ) {
            genreSheet()
                .presentationDetents([.height(sheetHeight)])
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isYearSeasonSheetPresented },
                set: { store.send(.yearSeasonSheetPresentedChanged($0)) }
            )
        ) {
            yearSeasonSheet()
                .presentationDetents([.height(sheetHeight)])
        }
    }

    // MARK: - 상단

    private func header() -> some View {
        return HStack(spacing: 0) {
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
    }

    private func filterBar() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(RankingReducer.Filter.allCases, id: \.self) { filter in
                    filterChip(filter)
                        .padding(.trailing, 8)
                }

                Spacer()

                Button {
                    store.send(.genreButtonTapped)
                } label: {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text(store.state.selectedGenre)
                                .textStyle(size: 16, color: .anipickSecondary)
                                .padding(.trailing, 8)

                            Image(.chevronDownBlue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.anipickSecondary)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    private func filterChip(_ filter: RankingReducer.Filter) -> some View {
        let isSelected = store.state.filter == filter
        let title =
            isSelected && filter == .yearSeason ? store.state.yearSeasonChipTitle : filter.rawValue
        return Button {
            store.send(.filterTapped(filter))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .textStyle(size: 13, color: isSelected ? .gray5 : .white)
                    .background(isSelected ? .anipickPrimary : .gray6)
                    .cornerRadius(32)
            }
        }
    }

    // MARK: - 목록

    private func rankingCell(_ item: RankedAnime) -> some View {
        return Button {
            store.send(.itemTapped(item))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    VStack(spacing: 0) {
                        Text("\(item.rank ?? 0)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                            .padding(.bottom, 8)

                        if store.state.filter == .realTime {
                            HStack(alignment: .center, spacing: 0) {
                                trendIndicator(item)
                            }
                        }
                    }
                    .padding(.trailing, 15)

                    AnimeCoverImage(url: item.coverImageUrl, width: 128, height: 182)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title ?? "-")
                            .lineLimit(2)
                            .font(.system(size: 16))
                            .foregroundStyle(.anipickBlack)
                            .multilineTextAlignment(.leading)

                        FlowChipLayout(spacing: 4) {
                            ForEach(item.genres ?? [], id: \.self) { genre in
                                genreChip(genre)
                                    .padding(.trailing, 4)
                            }
                        }
                        .padding(.trailing, 4)
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func trendIndicator(_ item: RankedAnime) -> some View {
        return HStack(spacing: 0) {
            if item.trend == "up" {
                Image(.upTrianglePink)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8)
            } else if item.trend == "down" {
                Image(.downTriangleBlue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8)
            } else {
                Rectangle()
                    .fill(.gray8)
                    .frame(width: 7, height: 1)
            }

            Spacer().frame(width: 3)

            Text(item.change.flatMap { Int($0) }.map { String(abs($0)) } ?? "")
                .foregroundStyle(trendColor(item))
                .font(.system(size: 14))
        }
    }

    private func trendColor(_ item: RankedAnime) -> Color {
        switch item.trend {
        case "up":
            return .point
        case "down":
            return .anipickSecondary
        default:
            return .gray8
        }
    }

    private func genreChip(_ title: String) -> some View {
        return VStack(spacing: 0) {
            Text(title)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .font(.system(size: 12))
                .foregroundStyle(.anipickPrimary)
                .background(.anipickPrimary.opacity(0.1))
                .cornerRadius(8)
                .lineLimit(1)
        }
    }

    // MARK: - 시트

    private func sheetHeader(_ title: String, onClose: @escaping () -> Void) -> some View {
        return HStack(spacing: 0) {
            Text(title)
                .textStyle(size: 16, color: .anipickBlack)
                .padding(.horizontal, 12)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(.xButton)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }

    private func sheetButtons(onReset: @escaping () -> Void, onDone: @escaping () -> Void)
        -> some View
    {
        return HStack(spacing: 0) {
            Spacer()

            Button {
                onReset()
            } label: {
                Text("초기화")
                    .font(.system(size: 14))
                    .foregroundStyle(.textGray)
            }

            Spacer().frame(width: 16)

            Button {
                onDone()
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

    private func genreSheet() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            sheetHeader("장르") {
                store.send(.genreSheetPresentedChanged(false))
            }

            ScrollView(showsIndicators: false) {
                FlowTagLayout {
                    ForEach(store.state.genres, id: \.self) { genre in
                        let isSelected = store.state.selectedGenre == genre
                        Button {
                            store.send(.genreTapped(genre))
                        } label: {
                            Text(genre)
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

            sheetButtons {
                store.send(.genreResetTapped)
            } onDone: {
                store.send(.genreDoneTapped)
            }
        }
        .background(.white)
        .frame(height: sheetHeight)
    }

    private func yearSeasonSheet() -> some View {
        return VStack(spacing: 0) {
            sheetHeader("년도/분기") {
                store.send(.yearSeasonSheetPresentedChanged(false))
            }

            HStack(spacing: 0) {
                Picker(
                    "",
                    selection: Binding(
                        get: { store.state.pickerYear },
                        set: { store.send(.pickerYearChanged($0)) }
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
                        get: { store.state.pickerSeason },
                        set: { store.send(.pickerSeasonChanged($0)) }
                    )
                ) {
                    ForEach(RankingReducer.seasons, id: \.self) {
                        Text("\($0)")
                            .textStyle(size: 18, color: .anipickSecondary)
                    }
                }
                .pickerStyle(.wheel)
            }

            Spacer()

            sheetButtons {
                store.send(.yearSeasonResetTapped)
            } onDone: {
                store.send(.yearSeasonDoneTapped)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .frame(height: sheetHeight)
        .onAppear {
            store.send(.yearSeasonSheetAppeared)
        }
    }
}
