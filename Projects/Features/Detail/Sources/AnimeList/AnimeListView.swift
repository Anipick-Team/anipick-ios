import DesignSystem
import DetailClientInterface
import MVICore
import SwiftUI

/// 레거시 `SeriesDetailView`·`RecommendedView`와 같은 배치 (배너 이미지·개수 줄만 다르다)
struct AnimeListView: View {
    @State private var store: Store<AnimeListReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: AnimeListReducer.State, reducer: AnimeListReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: AnimeListReducer.State {
        return store.state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BackNavigationBar(title: state.headerTitle) {
                store.send(.backTapped)
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 30)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 20)

            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 151)
                    .background(Color.black)
                    .cornerRadius(8)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(state.bannerText)
                            .textStyle(size: 24, color: .gray7, weight: .bold)
                            .padding(.top, 20)
                            .padding(.leading, 20)

                        Spacer()
                    }

                    Spacer()
                }

                Image(state.kind == .series ? .cloud : .recommendView)
                    .padding(.trailing, 20)
            }
            .frame(height: 151)

            Spacer().frame(height: 24)

            if state.kind == .series {
                Text("총 \(state.count)개")
                    .textStyle(size: 16, color: .gray8)
                    .padding(.bottom, 16)
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(state.items, id: \.self) { item in
                        TitledCoverImage(
                            url: item.coverImageUrl, width: nil, height: 162, title: item.title
                        )
                        .onTapGesture {
                            store.send(.itemTapped(item))
                        }
                        .onAppear {
                            store.send(.itemAppeared(item))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .navigationBarBackButtonHidden()
        .onAppear {
            store.send(.appeared)
        }
    }
}
