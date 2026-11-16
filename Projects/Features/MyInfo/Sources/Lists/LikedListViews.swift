import DesignSystem
import MVICore
import MyInfoClientInterface
import SwiftUI

/// 레거시 `LikeAnimeListView`와 같은 배치 (빈 화면 없음)
struct LikedAnimesView: View {
    @State private var store: Store<LikedAnimesReducer>

    init(state: LikedAnimesReducer.State, reducer: LikedAnimesReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ListScaffold(
            title: "좋아요한 작품",
            countText: "총 \(store.state.count)개",
            onBack: { store.send(.backTapped) }
        ) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: ListScaffold<EmptyView>.columns, spacing: 24) {
                    ForEach(store.state.items, id: \.self) { item in
                        Button {
                            store.send(.itemTapped(item))
                        } label: {
                            TitledCoverImage(
                                url: item.coverImageUrl, width: nil, height: 162, title: item.title)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            store.send(.appeared)
        }
    }
}

/// 레거시 `LikePersonListView`와 같은 배치 (빈 화면 없음)
struct LikedPersonsView: View {
    @State private var store: Store<LikedPersonsReducer>

    init(state: LikedPersonsReducer.State, reducer: LikedPersonsReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ListScaffold(
            title: "좋아요한 인물",
            countText: "총 \(store.state.count)명",
            onBack: { store.send(.backTapped) }
        ) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: ListScaffold<EmptyView>.columns, spacing: 24) {
                    ForEach(store.state.items, id: \.self) { person in
                        Button {
                            store.send(.itemTapped(person))
                        } label: {
                            TitledCoverImage(
                                url: person.profileImageUrl, width: nil, height: 133,
                                title: person.name)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            store.send(.itemAppeared(person))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            store.send(.appeared)
        }
    }
}
