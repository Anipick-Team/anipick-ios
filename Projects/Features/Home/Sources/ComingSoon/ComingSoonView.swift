import DesignSystem
import HomeClientInterface
import MVICore
import SwiftUI

/// 레거시 `ComingSoonView`와 같은 배치
struct ComingSoonView: View {
    @State private var store: Store<ComingSoonReducer>
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    init(state: ComingSoonReducer.State, reducer: ComingSoonReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 20)

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

                    Text("공개 예정")
                        .textStyle(size: 18, color: .anipickBlack)

                    Spacer()
                }

                Spacer().frame(height: 30)

                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 9)
                    .background(.gray7)

                HStack(spacing: 0) {
                    Spacer()

                    Button {
                        store.send(.sortButtonTapped)
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(store.state.sort.title)
                                .textStyle(size: 14, color: .gray8)
                                .padding(.trailing, 4)

                            Image(
                                systemName: store.state.isSortMenuPresented
                                    ? "chevron.up" : "chevron.down"
                            )
                            .resizable()
                            .foregroundColor(.gray8)
                            .frame(width: 9, height: 6)
                        }
                    }
                }
                .padding(20)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(store.state.items, id: \.self) { item in
                            cell(item)
                                .onAppear {
                                    store.send(.itemAppeared(item))
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            if store.state.isSortMenuPresented {
                sortMenu()
                    .padding(.trailing, 20)
                    .offset(y: 130)
                    .zIndex(2)
                    .animation(.easeInOut, value: store.state.isSortMenuPresented)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func cell(_ item: ComingSoonAnime) -> some View {
        return Button {
            store.send(.itemTapped(item))
        } label: {
            VStack(spacing: 0) {
                TitledCoverImage(
                    url: item.coverImageUrl, width: nil, height: 162, title: item.title)

                if let releaseDate = item.releaseDate {
                    Text(releaseDate)
                        .textStyle(size: 12, color: .gray8)
                }
            }
        }
    }

    private func sortMenu() -> some View {
        return VStack(spacing: 0) {
            ForEach(ComingSoonReducer.Sort.allCases, id: \.self) { sort in
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
}
