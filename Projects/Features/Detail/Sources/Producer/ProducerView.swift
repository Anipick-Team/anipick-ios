import DesignSystem
import DetailClientInterface
import MVICore
import SwiftUI

/// 레거시 `ProducerDetailView`와 같은 배치
struct ProducerView: View {
    @State private var store: Store<ProducerReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: ProducerReducer.State, reducer: ProducerReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: store.state.studioName) {
                store.send(.backTapped)
            }

            Spacer().frame(height: 30)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.state.groups, id: \.year) { group in
                        Rectangle()
                            .foregroundColor(.gray7)
                            .frame(height: 12)
                            .frame(maxWidth: .infinity)
                            .background(.gray5)

                        Spacer().frame(height: 24)

                        HStack(spacing: 0) {
                            yearTag(group.year)
                                .padding(.bottom, 20)
                                .padding(.leading, 20)

                            Spacer()
                        }

                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(group.animes.indices, id: \.self) { index in
                                let anime = group.animes[index]
                                Button {
                                    store.send(.animeTapped(anime))
                                } label: {
                                    VStack(spacing: 0) {
                                        TitledCoverImage(
                                            url: anime.coverImageUrl, width: nil, height: 162,
                                            title: anime.title)
                                    }
                                }
                                .onAppear {
                                    store.send(.animeAppeared(anime))
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 32)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func yearTag(_ year: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text(year)
                .padding(.vertical, 7)
                .padding(.horizontal, 8)
                .textStyle(size: 14, color: .anipickBlack)
                .background(Color.gray5)
                .cornerRadius(32)
        }
    }
}
