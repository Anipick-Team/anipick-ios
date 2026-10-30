import DesignSystem
import MVICore
import MyInfoClientInterface
import SwiftUI

/// 레거시 `ToWatchListView`·`WatchingListView`·`FinishedWatchingListView`와 같은 배치
struct WatchListView: View {
    @State private var store: Store<WatchListReducer>

    init(state: WatchListReducer.State, reducer: WatchListReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ListScaffold(
            title: store.state.title,
            countText: "총 \(store.state.count)개",
            onBack: { store.send(.backTapped) }
        ) {
            if store.state.count == 0 {
                emptyView()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: ListScaffold<EmptyView>.columns, spacing: 24) {
                        ForEach(store.state.items, id: \.self) { item in
                            cell(item)
                                .onAppear {
                                    store.send(.itemAppeared(item))
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            store.send(.appeared)
        }
    }

    private var emptyIcon: ImageResource {
        switch store.state.status {
        case .watchList:
            return .emptyToWatchListIcon
        case .watching:
            return .emptyViewIcon
        case .finished:
            return .emptyFinishedIcon
        }
    }

    private func emptyView() -> some View {
        return VStack(spacing: 0) {
            Spacer()

            Image(emptyIcon)
                .resizable()
                .frame(width: 148, height: 148)
                .padding(.bottom, 28)

            Text(store.state.emptyMessage)
                .textStyle(size: 16, color: .gray8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func cell(_ item: MyAnime) -> some View {
        return Button {
            store.send(.itemTapped(item))
        } label: {
            if store.state.status == .finished {
                VStack(alignment: .leading, spacing: 0) {
                    TitledCoverImage(
                        url: item.coverImageUrl, width: nil, height: 162, title: item.title)
                    ratingRow(item.myRating)
                }
            } else {
                TitledCoverImage(
                    url: item.coverImageUrl, width: nil, height: 162, title: item.title)
            }
        }
    }

    /// 다 본 애니만 (W6)
    @ViewBuilder
    private func ratingRow(_ rating: Double?) -> some View {
        if let rating {
            HStack(spacing: 0) {
                Text("내 평가")
                    .textStyle(size: 12, color: .gray8)
                    .padding(.trailing, 4)

                Image(.fillPickStar)
                    .resizable()
                    .frame(width: 12, height: 12)
                    .padding(.trailing, 2)

                Text("\(rating, specifier: "%.1f")")
                    .textStyle(size: 14, color: .point)

                Spacer()
            }
        } else {
            HStack(spacing: 0) {
                Text("아직 평가가 없어요.")
                    .textStyle(size: 12, color: .gray8)
                    .padding(.trailing, 4)

                Spacer()
            }
        }
    }
}
