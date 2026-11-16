import DesignSystem
import HomeClientInterface
import MVICore
import SwiftUI

/// 레거시 `RecommendedAnimeView`·`SimilarRecommendedAnimeView`와 같은 배치 (배너 문구만 다르다)
struct RecommendationListView: View {
    @State private var store: Store<RecommendationListReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: RecommendationListReducer.State, reducer: RecommendationListReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
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
                .padding(.top, 8)

                Spacer()

                Text("추천 애니메이션")
                    .textStyle(size: 18, color: .anipickBlack)

                Spacer()
            }

            Spacer().frame(height: 30)

            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                banner()
                    .frame(height: 151)
                    .padding(.bottom, 20)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(store.state.items, id: \.self) { item in
                        Button {
                            store.send(.itemTapped(item))
                        } label: {
                            TitledCoverImage(
                                url: item.coverImageUrl, width: nil, height: 162, title: item.title)
                        }
                        .onAppear {
                            store.send(.itemAppeared(item))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func banner() -> some View {
        return ZStack {
            Rectangle()
                .foregroundColor(.black)
                .cornerRadius(8)
                .frame(maxWidth: .infinity)

            VStack {
                HStack {
                    Text(store.state.bannerText)
                        .textStyle(size: 20, color: .gray5, weight: .bold)
                        .padding(.top, 12)
                        .padding(.leading, 24)

                    Spacer()
                }

                Spacer()
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Image(.cloud)
                        .padding(.horizontal, 24)
                }
            }
        }
    }
}
