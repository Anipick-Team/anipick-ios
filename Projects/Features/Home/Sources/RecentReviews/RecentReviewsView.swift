import DesignSystem
import MVICore
import ReviewClientInterface
import SwiftUI

/// 레거시 `RecentReviewView`와 같은 배치
struct RecentReviewsView: View {
    @State private var store: Store<RecentReviewsReducer>
    @State private var width: CGFloat = 0
    private let imageURL: (Int) -> URL

    init(
        state: RecentReviewsReducer.State, reducer: RecentReviewsReducer,
        imageURL: @escaping (Int) -> URL
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.imageURL = imageURL
    }

    private var state: RecentReviewsReducer.State {
        return store.state
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    HStack(alignment: .center, spacing: 0) {
                        Button {
                            store.send(.backTapped)
                        } label: {
                            Image(.chevronLeft)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 20)

                        Spacer()
                    }

                    Spacer()

                    Text("최근 리뷰")
                        .textStyle(size: 18, color: .anipickBlack)

                    Spacer()
                }
                .padding(.top, 12)

                Spacer().frame(height: 30)

                ZStack(alignment: .topLeading) {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global).minY) {
                                        if store.state.isBlockMenuPresented {
                                            store.send(.scrolled)
                                        }
                                    }
                            }
                            .frame(height: 0)

                            ForEach(state.reviews, id: \.reviewId) { review in
                                RecentReviewCell(
                                    review: review,
                                    profileImageURL: review.profileImageId.map(imageURL),
                                    onLikeTapped: {
                                        store.send(.likeTapped(review))
                                    },
                                    onMoreTapped: { frame in
                                        store.send(.moreButtonTapped(review, anchorY: frame.minY))
                                    }
                                )
                                .onTapGesture {
                                    store.send(.reviewTapped(review))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .onAppear {
                                    store.send(.reviewAppeared(review))
                                }
                            }
                        }
                        .cornerRadius(8)
                    }

                    if state.isBlockMenuPresented {
                        ReportBlockMenu {
                            store.send(.reportMenuTapped)
                        } blockAction: {
                            store.send(.blockMenuTapped)
                        }
                        // 레거시: 화면 너비 - 70, ⋮ 버튼의 화면 위치 - 40
                        .position(x: width - 70, y: state.menuAnchorY - 40)
                        .zIndex(1000)
                    }
                }
            }
            .background(.gray7)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                store.send(.disappeared)
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if state.isBlockToastPresented {
                        toast("사용자 차단이 완료되었습니다.")
                    }
                    if state.isReportToastPresented {
                        toast("신고가 정상적으로 접수되었습니다.")
                    }
                }
            }
            .animation(.default, value: state.isBlockToastPresented)
            .animation(.default, value: state.isReportToastPresented)

            if state.isReportPopupPresented {
                ReportReasonPopup {
                    store.send(.reportCancelled)
                } okAction: { reason in
                    store.send(.reportConfirmed(reason: reason))
                }
            }

            if state.isBlockPopupPresented {
                BlockUserPopup {
                    store.send(.blockCancelled)
                } okAction: {
                    store.send(.blockConfirmed)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            return proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        .onAppear {
            store.send(.appeared)
        }
    }

    private func toast(_ message: String) -> some View {
        return Text(message)
            .textStyle(size: 14, color: .gray5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.anipickBlack)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
