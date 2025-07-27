//
//  HomeSearchView.swift
//  AniPick
//
//  Created by cho on 5/11/25.
//

import SwiftUI

struct HomeSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: HomeSearchViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var selectedTab: SearchTab = .initSearch
    @State private var tabWidths: [SearchTab: CGFloat] = [:]
    let dummy = makeDummyHomeSearchResponse()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    DLog("HomeSearchView - dismiss")
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 12)
                
                HStack {
                    if viewModel.searchText.isEmpty {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray8)
                    }
                    
                    TextField("무엇을 검색할까요?", text: $viewModel.searchText)
                        .foregroundColor(.primary)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .onSubmit {
                            // TODO: 검색어 완료 시, 작품, 인물, 제작사에 데이터 불러오는 api 여기서 불러야함
                            if !viewModel.searchText.isEmpty {
                                self.viewModel.saveRecentKeyword(self.viewModel.searchText)
                                if self.viewModel.isShowRecentKeyword == false {
                                    self.viewModel.isShowRecentKeyword = true
                                }
                                self.selectedTab = .animation
                            }
                        }
                        .onChange(of: viewModel.searchText) { newValue in
                            if newValue.isEmpty {
                                selectedTab = .initSearch // 텍스트가 비면 initSearch로 돌아감
                            }
                        }
                    
                    Button {
                        self.viewModel.searchText = ""
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
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
                switch selectedTab {
                case .animation:
                    self.selectAnimationView(animeList: self.viewModel.initAnimeList)
                case .person:
                    self.selectPersonView(info: dummy?.result?.persons ?? [])
                case .producer:
                    self.selectProducerView(studioInfo: dummy?.result?.studios ?? [])
                case .initSearch:
                    self.initSearchView(animeList: self.viewModel.initAnimeList)
                }

        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.viewModel.checkRecentKeywordList()
            Task {
                await self.viewModel.getInitSearchList()
            }
        }
    }
    
    private func getCountString(info: HomeSearchResult?, tab: SearchTab) -> Int? {
        switch tab {
        case .animation:
            return info?.count
        case .person:
            return info?.personCount
        case .producer:
            return info?.studioCount
        case .initSearch:
            return nil
        }
    }
    
    private func subTabView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SearchTab.visibleTabs) { tab in
                    Button {
                        withAnimation(.easeInOut) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text(tab.rawValue)
                                    .customFontStyle(size: 16, color: selectedTab == tab ? .anipickBlack : .gray8)
                                    .padding(.trailing, 2)
                                
                                let count = self.getCountString(info: dummy?.result, tab: tab)
                                Text("\(count)건")
                                    .customFontStyle(size: 14, color: .gray6)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 16)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: TabWidthPreferenceKey.self, value: [tab: geo.size.width])
                                }
                            )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .onPreferenceChange(TabWidthPreferenceKey.self) { value in
                tabWidths = value
            }
            
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 3)
                if let width = tabWidths[selectedTab],
                   let index = SearchTab.allCases.firstIndex(of: selectedTab) {
                    let leading = SearchTab.allCases[..<index].reduce(CGFloat(0)) { result, tab in
                        result + (tabWidths[tab] ?? 0)
                    }
                    
                    Rectangle()
                        .fill(.anipickBlack)
                        .frame(width: width - 24, height: 2)
                        .offset(x: leading)
                        .animation(.easeInOut, value: selectedTab)
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
    
    private func initSearchView(animeList: [Anime]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            if self.viewModel.isShowRecentKeyword {
                self.searchingView()
                    .padding(.horizontal, -20)
            }
            
            ScrollView {
                HStack(spacing: 0) {
                    Text("인기 작품")
                        .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                        
                    Spacer()
                }
                .padding(.bottom, 17)
                .frame(maxWidth: .infinity)
                
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<20) { _ in
                        let anime = Anime(animeId: 1, title: "asdfasdfasdf", coverImageUrl: "sdfsdf", releaseDate: "asdfaf")
                        animationCell(anime: anime) {
                                DLog("인기 작품 cell 탭탭")
                                viewModel.moveToAnimeDetailView(animeId: anime.animeId ?? 0)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    private func selectProducerView(studioInfo: [Studio]?) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            self.subTabView()
            // TODO: 몇개인지 정확하게 추출
            Text("총 \(studioInfo?.count)개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                ForEach(studioInfo!, id: \.self) { item in
                    self.producerCell(studio: item)
                        .padding(.vertical, 6)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    

    // SearchStudioQueryResponse
    private func producerCell(studio: Studio) -> some View {
        return HStack(spacing: 0) {
            Text(studio.name)
                .font(.system(size: 14))
                .foregroundStyle(.anipickBlack)
            
            Spacer()
            
            Button {
                DLog("제작세 detail로 이동")
            } label: {
                Image(.chevronLeftGray)
                    .resizable()
                    .frame(width: 18, height: 18)
            }
            
        }
    }
    
    private func selectAnimationView(animeList: [Anime]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            self.subTabView()

            // TODO: 몇명 인지 정확하게 추출
            Text("총 19개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(animeList, id: \.self) { anime in
                        animationCell(anime: anime) {
                            DLog("애니메 작어어업")
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    private func selectPersonView(info: [Person]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            self.subTabView()
            
            // TODO: 몇명 인지 정확하게 추출
            Text("총 4명")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(0..<4) { _ in
                        self.personCell()
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    private func searchingView() -> some View {
        let recentSearchList = UserDefaultsManager.shared.getHomeRecentKeyword()
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("최근 검색어")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button {
                    DLog("최근 검색어 전체 삭제")
                    self.viewModel.clearAllRecentKeywordList()
                } label: {
                    Text("전체삭제")
                        .foregroundStyle(.gray6)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(self.viewModel.recentKeywordList, id: \.self) { keyword in
                        recentSearchKeyword(keyword: keyword)
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
    
    private func animationCell(anime: Anime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // 회색 배경 정사각형
                    if let url = anime.coverImageUrl {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                // 로딩 중 placeholder
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(anime.title ?? "-")
                    .font(.system(size: 14))
                    .lineLimit(2)
                    .padding(.top, 6)
            }
        }
    }
    
    private func personCell() -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 105)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("사아람이름")
               // .frame(width: 128, height: 45)
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
    
    private func recentSearchKeyword(keyword: String) -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(keyword)
                    .foregroundColor(.anipickBlack)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.trailing, 8)
                
                Button {
                    self.viewModel.removeSpecificKeyword(keyword)
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

#Preview {
    AppDIContainer.makeHomeSearchView()
}
