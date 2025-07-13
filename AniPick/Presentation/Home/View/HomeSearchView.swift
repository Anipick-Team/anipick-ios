//
//  HomeSearchView.swift
//  AniPick
//
//  Created by cho on 5/11/25.
//

import SwiftUI

enum SearchTab: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case animation = "작품"
    case person = "인물"
    case producer = "제작사"
    case initSearch = "인기 작품"
}

struct HomeSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchString: String = ""
    
    @State private var selectedTab: SearchTab = .animation
    @State private var tabWidths: [SearchTab: CGFloat] = [:]
    @State private var isShowRecentKeyword: Bool = false
    @State private var recentKeywordList: [String] = []
    
    @StateObject var viewModel: HomeSearchViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    print("홈-검색에서 뒤로가기 버튼 탭탭")
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 12)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray8)
                     
                    TextField("무엇을 검색할까요?", text: $searchString)
                        .foregroundColor(.primary)
                        .disableAutocorrection(true)
                    
                    Button {
                        searchString = ""
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
            
            // TODO: 검색이 완료 되었을 시 - 작품, 인물, 제작사 별 다르게 화면 나오도록 수정
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(SearchTab.allCases) { tab in
                        Button {
                            withAnimation(.easeInOut) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                // 텍스트와 width 측정
                                Text(tab.rawValue)
                                    .padding(.trailing, 24)
                                    .padding(.bottom, 16)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedTab == tab ? .anipickBlack : .gray8)
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
                // Indicator
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
            }
            .padding(.top, 8)
            .padding(.leading, 20)
            
            Rectangle()
                .foregroundColor(.gray5)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .background(.gray5)
            
            
            Spacer().frame(height: 20)
            
            // TODO: 최근 검색어 저장 및 없으면 만드는 거 만들어야함!
            if self.isShowRecentKeyword {
                self.searchingView()
            }

//            Group {
                switch selectedTab {
                case .animation:
                    self.selectAnimationView(animeList: self.viewModel.initAnimeList)
                case .person:
                    self.selectPersonView()
                case .producer:
                    self.selectProducerView()
                case .initSearch:
                    self.initSearchView(animeList: self.viewModel.initAnimeList)
                }
//            }
            
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            self.checkRecentSearchKeyword()
            Task {
                await self.viewModel.getInitSearchList()
            }
        }
    }
    private func initSearchView(animeList: [Anime]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(animeList, id: \.self) { anime in
                        animationCell(anime: anime)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    private func selectProducerView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            // TODO: 몇개인지 정확하게 추출
            Text("총 5개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                ForEach(0..<12) { _ in
                    self.producerCell()
                        .padding(.vertical, 6)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    
    private func checkRecentSearchKeyword() {
        let keywords = UserDefaultsManager.shared.getHomeRecentKeyword()
        if keywords.isEmpty {
            DLog("최근 검색어 비어있음")
            self.isShowRecentKeyword = false
        } else {
            self.isShowRecentKeyword = true
            self.recentKeywordList = keywords
        }
    }
    private func producerCell() -> some View {
        return HStack(spacing: 0) {
            Text("제작사명")
                .font(.system(size: 14))
                .foregroundStyle(.anipickBlack)
            
            Spacer()
            
            Button {
                print("제작사 이동이동")
            } label: {
                Image(.chevronLeftGray)
                    .resizable()
                    .frame(width: 18, height: 18)
            }
            
        }
    }
    
    private func selectAnimationView(animeList: [Anime]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            // TODO: 몇명 인지 정확하게 추출
            Text("총 19개")
                .font(.system(size: 14))
                .foregroundStyle(.gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(animeList, id: \.self) { anime in
                        animationCell(anime: anime)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }
    
    private func selectPersonView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
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
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("최근 검색어")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button {
                    DLog("최근 검색어 전체 삭제")
                    self.isShowRecentKeyword = false
                    UserDefaultsManager.shared.clearHomeRecentKeyword()
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
                    ForEach(0..<5) { _ in
                        recentSearchKeyword(keyword: "귀칼")
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
            
//            VStack(alignment: .leading, spacing: 0) {
//                Text("인기 작품")
//                    .font(.system(size: 20, weight: .semibold))
//                    .foregroundStyle(.anipickBlack)
//                    .padding(.bottom, 16)
//                
//                ScrollView {
//                    LazyVGrid(columns: columns, spacing: 24) {
//                        ForEach(0..<12) { _ in
//                            animationCell()
//                        }
//                    }
//                }
//                .scrollIndicators(.hidden)
//                
//            }
//            .padding(.horizontal, 20)
        }
    }
    
    private func animationCell(anime: Anime) -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                AsyncImage(url: URL(string: anime.coverImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        // 로딩 중 placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 128, height: 174)
                            .clipped()
                        
                    case .failure:
                        // 실패 시 fallback
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.4))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                        
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(anime.title ?? "-")
               // .frame(width: 128, height: 45)
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
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
                    print("keyword 삭제 - \(keyword)")
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
