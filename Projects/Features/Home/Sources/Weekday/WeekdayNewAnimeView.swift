import DesignSystem
import HomeClientInterface
import MVICore
import SwiftUI

/// 레거시 `WeekdayNewAnimeView`(PR #18)와 같은 배치
struct WeekdayNewAnimeView: View {
    @State private var store: Store<WeekdayNewAnimeReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: WeekdayNewAnimeReducer.State, reducer: WeekdayNewAnimeReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: WeekdayNewAnimeReducer.State {
        return store.state
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            scheduleNotice

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    weekdayPicker

                    HStack(spacing: 0) {
                        Spacer()

                        Menu {
                            ForEach(WeekdayNewAnimeReducer.Sort.allCases) { sort in
                                Button(sort.title) {
                                    store.send(.sortSelected(sort))
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(state.sort.title)
                                    .textStyle(size: 14, color: .gray8)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.gray8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    if state.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if state.animes.isEmpty {
                        Text("해당 요일에 등록된 신작이 없어요.")
                            .textStyle(size: 14, color: .gray8)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                            ForEach(state.animes, id: \.self) { item in
                                Button {
                                    store.send(.itemTapped(item))
                                } label: {
                                    TitledCoverImage(
                                        url: item.coverImageUrl, width: nil, height: 162,
                                        title: item.title)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    store.send(.itemAppeared(item))
                                }
                            }
                        }

                        if state.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .simultaneousGesture(daySwipeGesture)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .task {
            store.send(.appeared)
        }
    }

    /// 가로 방향이 우세한 스와이프만 요일 이동으로 처리해 세로 스크롤과 겹치지 않게 한다.
    private var daySwipeGesture: some Gesture {
        return DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else {
                    return
                }
                store.send(dx < 0 ? .swipedToNextDay : .swipedToPreviousDay)
            }
    }

    private var header: some View {
        return ZStack {
            HStack(spacing: 0) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            Text("요일별 신작")
                .textStyle(size: 18, color: .anipickBlack, weight: .semibold)
        }
        .frame(height: 58)
        .background(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
    }

    // Figma `배너`: 위아래 10·좌우 20, 간격 10, 배경 #F3F3F3
    private var scheduleNotice: some View {
        return HStack(spacing: 10) {
            // Figma `Ellipse 172`: 34.24x34.24, 채움 #E3E3E3, 테두리 1px #CCCCCC
            Circle()
                .fill(Color(red: 227 / 255, green: 227 / 255, blue: 227 / 255))
                .overlay(
                    Circle().stroke(
                        Color(red: 204 / 255, green: 204 / 255, blue: 204 / 255), lineWidth: 1)
                )
                .overlay(
                    // Figma `Union`: 6.96x16.1, #000000
                    Image(.infoIcon)
                        .resizable()
                        .frame(width: 7, height: 16)
                )
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            Text("제공되는 정보는 공식 방영 일정을 기준으로 하며,\nOTT 플랫폼별 방영 일정과는 다를 수 있습니다.")
                .textStyle(size: 11, color: .black)
                .lineSpacing(2)  // 줄 높이 15.4pt(140%)에 맞춘 근사값
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 243 / 255, green: 243 / 255, blue: 243 / 255))
    }

    private var weekdayPicker: some View {
        return HStack(spacing: 8) {
            ForEach(WeekdayNewAnimeDay.allCases) { day in
                let isSelected = state.day == day
                Button {
                    store.send(.daySelected(day))
                } label: {
                    Text(day.title)
                        .textStyle(size: 14, color: isSelected ? .white : .gray8, weight: .semibold)
                        .frame(width: 44, height: 44)
                        .background(isSelected ? Color.anipickPrimary : Color.gray7)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 38)
    }
}
