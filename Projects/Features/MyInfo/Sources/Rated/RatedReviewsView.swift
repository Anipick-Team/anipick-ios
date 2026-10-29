import DesignSystem
import MVICore
import MyInfoClientInterface
import SwiftUI

/// 레거시 `RatedAnimeListView`와 같은 배치
struct RatedReviewsView: View {
    @State private var store: Store<RatedReviewsReducer>
    /// 메뉴 위치를 정하는 화면 좌표 (레이아웃 값이라 View가 들고 있다, 레거시와 같음)
    @State private var sortButtonFrame: CGRect = .zero
    @State private var reviewMenuAnchor: CGRect = .zero
    private let reloadNotification: Notification.Name?

    init(
        state: RatedReviewsReducer.State,
        reducer: RatedReviewsReducer,
        reloadNotification: Notification.Name? = nil
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.reloadNotification = reloadNotification
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                BackNavigationBar(title: "평가한 작품") {
                    store.send(.backTapped)
                }
                .padding(.top, 12)

                Spacer().frame(height: 30)

                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) {
                                store.send(.scrolled)
                            }
                    }
                    .frame(height: 0)

                    content()

                    GeometryReader { proxy in
                        Color.clear
                            .frame(height: 1)
                            .preference(
                                key: RatedScrollOffsetKey.self,
                                value: proxy.frame(in: .named("SortOverlayArea")).minY
                            )
                    }
                }
                .coordinateSpace(name: "SortOverlayArea")
                .onPreferenceChange(RatedScrollOffsetKey.self) { _ in
                    if store.state.isSortMenuPresented {
                        store.send(.sortMenuClosedByScroll)
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if store.state.isSortMenuPresented {
                sortMenu()
                    .frame(width: 120)
                    .position(x: sortButtonFrame.maxX - 40, y: sortButtonFrame.maxY + 64)
            }

            if store.state.isReviewMenuPresented {
                reviewMenu()
                    .position(x: reviewMenuAnchor.minX, y: reviewMenuAnchor.minY + 50)
            }
        }
        .background(Color.gray7)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.appeared)
        }
        .onReceive(
            NotificationCenter.default.publisher(for: reloadNotification ?? .ratedReviewsNoReload)
        ) { _ in
            store.send(.reloadRequested)
        }
        .onDisappear {
            store.send(.disappeared)
        }
        .overlay(alignment: .top) {
            if store.state.isDeleteToastPresented {
                Text("리뷰 삭제가 완료되었습니다.")
                    .textStyle(size: 14, color: .gray5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.anipickBlack)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        store.send(.toastDismissed)
                    }
            }
        }
        .animation(.default, value: store.state.isDeleteToastPresented)
    }

    private func content() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)

            HStack(alignment: .center, spacing: 0) {
                Text("총 \(store.state.totalCount ?? 0)개")
                Spacer()

                Button {
                    store.send(.sortButtonTapped)
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        Text(store.state.sort.title)
                            .padding(.trailing, 4)
                        Image(
                            systemName: store.state.isSortMenuPresented
                                ? "chevron.up" : "chevron.down"
                        )
                        .resizable()
                        .frame(width: 9, height: 6)
                    }
                }
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .global)
                } action: {
                    sortButtonFrame = $0
                }
            }
            .textStyle(size: 14, color: .gray8)
            .foregroundColor(Color.gray8)
            .padding(.bottom, 13)

            Button {
                store.send(.reviewOnlyTapped)
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text("리뷰만 보기")
                        .padding(.trailing, 4)

                    Image(store.state.isReviewOnly ? .toggleEnable : .toggleDisable)

                    Spacer()
                }
            }
            .textStyle(size: 14, color: store.state.isReviewOnly ? .anipickSecondary : .gray8)

            Spacer().frame(height: 20)

            if store.state.reviews.isEmpty {
                emptyView()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.reviews, id: \.self) { review in
                        RatedReviewCell(review: review) { anchor in
                            reviewMenuAnchor = anchor
                            store.send(.moreTapped(review))
                        } onTapped: {
                            store.send(.cellTapped(review))
                        }
                        .onAppear {
                            store.send(.itemAppeared(review))
                        }
                    }
                    .padding(.bottom, 12)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .background(Color.gray7)
    }

    private func emptyView() -> some View {
        return VStack(spacing: 0) {
            Spacer()
                .frame(height: 120)

            Image(.emptyToWatchListIcon)
                .resizable()
                .frame(width: 148, height: 148)
                .padding(.bottom, 28)

            Text("앗! 아직 평가한 작품이 없네요.")
                .textStyle(size: 16, color: .gray8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// 레거시 `SortDropdownView`
    private func sortMenu() -> some View {
        return VStack(spacing: 0) {
            ForEach(RatedSort.allCases, id: \.self) { sort in
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

    /// 레거시 `MyReviewPopupView`
    private func reviewMenu() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    store.send(.deleteTapped)
                } label: {
                    Text("삭제")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }

                Rectangle()
                    .padding(.horizontal, 15)
                    .foregroundStyle(.gray5)
                    .frame(height: 1)

                Button {
                    store.send(.editTapped)
                } label: {
                    Text("수정")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }
            }
            .frame(width: 72)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .border(.gray5)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .cornerRadius(8)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(1)
        }
    }
}

private struct RatedScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension RatedSort {
    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .likes:
            return "좋아요 순"
        case .ratingDesc:
            return "평가 높은 순"
        case .ratingAsc:
            return "평가 낮은 순"
        }
    }
}

extension Notification.Name {
    /// 다시 받을 알림을 주지 않았을 때 듣는 이름 (아무도 보내지 않는다)
    fileprivate static let ratedReviewsNoReload = Notification.Name("RatedReviewsView.noReload")
}
