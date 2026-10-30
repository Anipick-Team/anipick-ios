import DesignSystem
import HomeClientInterface
import MVICore
import SwiftUI

/// 레거시 `HomeSearchView`와 같은 배치. 하위 탭 밑줄 위치를 재는 탭 너비는 레이아웃 상태라 View가 들고 있다.
struct HomeSearchView: View {
    typealias Tab = HomeSearchReducer.Tab

    @State private var store: Store<HomeSearchReducer>
    @State private var tabWidths: [Tab: CGFloat] = [:]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let personColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    init(state: HomeSearchReducer.State, reducer: HomeSearchReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private var state: HomeSearchReducer.State {
        return store.state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar()
                .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            switch state.selectedTab {
            case .animation:
                animationResults()
            case .person:
                personResults()
            case .producer:
                producerResults()
            case .initSearch:
                initSearch()
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.appeared)
        }
    }

    private func searchBar() -> some View {
        return HStack(spacing: 0) {
            Button {
                store.send(.backTapped)
            } label: {
                Image(.chevronLeft)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .padding(.trailing, 12)

            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if state.searchText.isEmpty {
                        HStack(spacing: 0) {
                            Text("무엇을 검색할까요?")
                                .textStyle(size: 14, color: .gray8)
                        }
                        .padding(.leading, 4)  // 커서와 살짝 띄우기
                    }

                    TextField(
                        "",
                        text: Binding(
                            get: { store.state.searchText },
                            set: { store.send(.searchTextChanged($0)) })
                    )
                    .foregroundStyle(.anipickBlack)
                    .disableAutocorrection(true)
                    .submitLabel(.done)
                    .padding(.leading, 4)  // placeholder와 동일한 padding
                    .onSubmit {
                        store.send(.submitted)
                    }
                }

                if state.searchText.isEmpty {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray8)
                        .padding(.trailing, 8)
                }

                Button {
                    store.send(.clearTapped)
                } label: {
                    Image(.allClearButton)
                        .foregroundColor(.gray8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.gray5)
            .cornerRadius(12)
        }
    }

    private func subTabs() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Tab.visibleTabs, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut) {
                            _ = store.send(.tabSelected(tab))
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text(tab.rawValue)
                                    .textStyle(
                                        size: 16,
                                        color: state.selectedTab == tab ? .anipickBlack : .gray8
                                    )
                                    .padding(.trailing, 2)

                                Text("\(state.count(of: tab))건")
                                    .textStyle(size: 14, color: .gray6)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 16)
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                return proxy.size.width
                            } action: { width in
                                tabWidths[tab] = width
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            ZStack(alignment: .leading) {
                Color.clear.frame(height: 3)

                if let width = tabWidths[state.selectedTab],
                    let index = Tab.allCases.firstIndex(of: state.selectedTab)
                {
                    let leading = Tab.allCases[..<index].reduce(CGFloat(0)) { result, tab in
                        result + (tabWidths[tab] ?? 0)
                    }
                    Rectangle()
                        .fill(.anipickBlack)
                        .frame(width: width - 24, height: 2)
                        .offset(x: leading)
                        .animation(.easeInOut, value: state.selectedTab)
                }
            }

            Rectangle()
                .foregroundColor(.gray5)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 20)
        }
    }

    private func initSearch() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            if state.isRecentKeywordsShown {
                recentKeywords()
                    .padding(.horizontal, -20)
            }

            ScrollView(showsIndicators: false) {
                HStack(spacing: 0) {
                    Text("인기 작품")
                        .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                    Spacer()
                }
                .padding(.bottom, 17)
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(state.popularAnimes, id: \.self) { anime in
                        Button {
                            store.send(.animeTapped(animeId: anime.animeId))
                        } label: {
                            TitledCoverImage(
                                url: anime.coverImageUrl, width: nil, height: 162,
                                title: anime.title)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private func animationResults() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            subTabs()

            Text("총 \(state.animeCount)개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(state.animes, id: \.self) { anime in
                        Button {
                            store.send(.animeTapped(animeId: anime.animeId))
                        } label: {
                            TitledCoverImage(
                                url: anime.coverImageUrl, width: nil, height: 162,
                                title: anime.title)
                        }
                        .onAppear {
                            store.send(.animeAppeared(anime))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private func personResults() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            subTabs()

            // 받은 인원 수를 보여 준다 (서버 전체 개수가 아님 — 레거시 그대로)
            Text("총 \(state.persons.count)명")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: personColumns, spacing: 0) {
                    ForEach(state.persons, id: \.self) { person in
                        Button {
                            store.send(.personTapped(person))
                        } label: {
                            TitledCoverImage(
                                url: person.profileImage, width: nil, height: 105,
                                title: person.name)
                        }
                        .onAppear {
                            store.send(.personAppeared(person))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private func producerResults() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            subTabs()

            Text("총 \(state.studios.count)개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                ForEach(state.studios, id: \.self) { studio in
                    Button {
                        store.send(.studioTapped(studio))
                    } label: {
                        HStack(spacing: 0) {
                            Text(studio.name ?? "--")
                                .font(.system(size: 14))
                                .foregroundStyle(.anipickBlack)

                            Spacer()

                            // 레거시: 안쪽 버튼은 아무 일도 하지 않는다
                            Button {
                            } label: {
                                Image(.chevronLeftGray)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .onAppear {
                        store.send(.studioAppeared(studio))
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private func recentKeywords() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("최근 검색어")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Button {
                    store.send(.clearAllKeywordsTapped)
                } label: {
                    Text("전체삭제")
                        .foregroundStyle(.gray6)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(state.recentKeywords, id: \.self) { keyword in
                        keywordChip(keyword)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(.horizontal, 20)

            Rectangle()
                .foregroundColor(.clear)
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .background(.gray7)
                .padding(.vertical, 20)
        }
    }

    private func keywordChip(_ keyword: String) -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    store.send(.keywordTapped(keyword))
                } label: {
                    Text(keyword)
                        .foregroundColor(.anipickBlack)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.trailing, 8)
                }

                Button {
                    store.send(.keywordRemoved(keyword))
                } label: {
                    Image(.recentKeywordClearX)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(.gray5, lineWidth: 1)
            )
        }
    }
}
