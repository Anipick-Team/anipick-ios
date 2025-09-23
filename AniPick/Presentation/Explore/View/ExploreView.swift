//
//  ExploreView.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

enum ExploreFilterTab: String, CaseIterable {
    case yearQuarter = "년도/분기"
    case genre = "장르"
    case type = "타입"
}

struct ExploreView: View {
    @StateObject var viewModel: ExploreViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var selectedTab: ExploreFilterTab = .genre
    @State private var isPresentYearFilter: Bool = false
    
    @State private var fromHomeupcoming: Bool = false
    
    // UI체크용
    @State private var selectedGenre: String = ""
    @State private var sheetHeight: CGFloat = 400
    
    var currentList: [String] {
           switch selectedTab {
               // quator -> 분기는 1,2,3,4 분기로 나누어져있어서 따로 받아와서 처리 X
           case .yearQuarter: return UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
           case .genre: return UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
           case .type: return UserDefaultsManager.shared.getMetaDataForType()
           }
       }
    
    let quarterList = ["전체 분기", "1분기", "2분기", "3분기", "4분기"]
    
    @State private var exploreRequestItem: ExploreReqeustItem? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                
                self.headerView()
                
                Spacer().frame(height: 16)
                
                HStack(spacing: 0) {
                    self.filterCategoryButtonView(selectedTab: .yearQuarter)
                        .padding(.trailing, 8)
                    
                    self.filterCategoryButtonView(selectedTab: .genre)
                        .padding(.trailing, 8)
                    
                    self.filterCategoryButtonView(selectedTab: .type)
                    
                }
                .padding(.horizontal, 20)
                
                if viewModel.selectedItems.isEmpty == false {
                    self.selectredCategoryView(selectedItems: viewModel.selectedItems)
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Button {
                        DLog("인기순 탭탭")
                        self.viewModel.isShowSortOptionView.toggle()
                    } label: {
                        Text("인기순")
                            .customFontStyle(size: 14, color: .gray8)
                            .padding(.trailing, 20)
                    }
                }
                .padding(.vertical, 20)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.exploreItems, id: \.animeId) { item in
                            animationCell(item: item) {
                                self.viewModel.tappedAnime(animeId: item.animeId ?? 0)
                            }
                            .onAppear {
                                if item == viewModel.exploreItems.last {
                                    DLog("explore 데이터 확인 - \(item) -- \(viewModel.exploreItems.last)")
                                    viewModel.fetchFiletedExploreData()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .sheet(isPresented: $isPresentYearFilter) {
                filterSelectedHalfModalView()
                    .presentationDetents([.height(self.sheetHeight)])
                //                .onHeightChange { newHeight in
                //                    self.sheetHeight = newHeight
                //                }
                
            }
            .background(Color.white)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // TODO: 무한스크롤은 와안성
                //viewModel.getExploreItems(category: .popularity)
                if fromHomeupcoming {
                    self.fromHomeupcoming = false
                } else {
                    viewModel.fetchFiletedExploreData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didSelectSeason)) { notification in
                if let userInfo = notification.userInfo,
                   let season = userInfo["season"] as? Int,
                   let year = userInfo["seasonYear"] as? Int {
                    self.viewModel.selectedSeason = String(season)
                    self.viewModel.selectedYear = String(year)
                    viewModel.fetchFiletedExploreData()
                    DLog("📥 받음: season=\(season), year=\(year)")
                    self.fromHomeupcoming = true
                }
            }
            
            if viewModel.isShowSortOptionView {
                getSortOptionView(sort: viewModel.selectedCategory)
                    .padding(.trailing, 20)
                    .offset(y: 160)
                    .zIndex(2)
                    .animation(.easeInOut, value: viewModel.isShowSortOptionView)
            }
            
            
        }
        
    }
    
    private func filterCategoryButtonView(selectedTab: ExploreFilterTab) -> some View {
        let isSelectedFilter = self.isSelectedFilter(selectedTab: selectedTab)
        return VStack(spacing: 0) {
            Button {
                DLog("\(selectedTab.rawValue) tapped")
                self.selectedTab = selectedTab
                self.isPresentYearFilter.toggle()
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text(selectedTab.rawValue)
                        .font(.system(size: 16))
                        .foregroundStyle(isSelectedFilter ? .anipickSecondary : .textBlack)
                        .padding(.trailing, 10)
                    
                    Image(isSelectedFilter ? .chevronDownBlue : .chevronDownGray)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(isSelectedFilter ? .anipickSecondary : .gray5, lineWidth: 1)
                )
                .foregroundStyle(.anipickBlack)
            }
        }
    }
    
    private func isSelectedFilter(selectedTab: ExploreFilterTab) -> Bool {
        switch selectedTab {
        case .yearQuarter:
            return viewModel.countForYear > 0
        case .genre:
            return viewModel.countForGenre > 0
        case .type:
            return viewModel.countFOrType > 0
        }
    }
    
    private func selectredCategoryView(selectedItems: [String]) -> some View {
        return
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.gray5)
                
                Spacer().frame(height: 12)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(selectedItems, id: \.self) { item in
                            HStack(spacing: 0) {
                                Text(item)
                                    .padding(.trailing, 4)
                                    .customFontStyle(size: 14, color: .anipickPrimary)
                                
                                Button {
                                    DLog("viewModel에서 해당 값 삭제삭제")
                                    if let index = viewModel.selectedItems.firstIndex(of: item) {
                                        viewModel.removeTagView(index: index)
                                    }
                                } label: {
                                    Image(.xButtonGreen)
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.anipickPrimary.opacity(0.2))
                            .cornerRadius(32)
                        }
                        .padding(.trailing, 4)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 12)
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.gray5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        
    }
    
    private func filterSelectedHalfModalView() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    self.selectedTab = .yearQuarter
                } label: {
                    Text("년도/분기")
                        .padding(.horizontal, 12)
                        .font(.system(size: 16))
                        .foregroundStyle(self.selectedTab == .yearQuarter ? .anipickBlack : .textGray)
                    
                }
                
                Button {
                    self.selectedTab = .genre
                } label: {
                    Text("장르")
                        .padding(.horizontal, 12)
                        .font(.system(size: 16))
                        .foregroundStyle(self.selectedTab == .genre ? .anipickBlack : .textGray)
                }
                
                
                Button {
                    self.selectedTab = .type
                } label: {
                    Text("타입")
                        .padding(.horizontal, 12)
                        .font(.system(size: 16))
                        .foregroundStyle(self.selectedTab == .type ? .anipickBlack : .textGray)
                }
                
                
                Spacer()
                
                
                Button {
                    print("닫기 탭탭")
                    self.isPresentYearFilter.toggle()
                } label: {
                    Image(.xButton)
                        .frame(width: 12, height: 12)
                }
            }
            .foregroundStyle(.textBlack)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
            
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray7)
            
            
            if self.selectedTab == .yearQuarter {
                // TODO: wheel picker Custom 하게 구현 -> Color 색상 변경 가능하도록 수정
                HStack(spacing: 0) {
                    Picker("", selection: $viewModel.selectedYear) {
                        ForEach(currentList, id: \.self) {
                            Text($0)
                                .customFontStyle(size: 14, color: .anipickBlack)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("", selection: $viewModel.selectedSeason) {
                        ForEach(quarterList, id: \.self) {
                            Text($0)
                                .customFontStyle(size: 14, color: .anipickBlack)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } else if selectedTab == .genre {
                ScrollView {
                    FlowLayout() {
                        ForEach(currentList, id: \.self) { item in
                            Button {
                                let genreList = UserDefaultsManager.shared.getMetaDataForGenres()
                                guard let id = genreList.first(where: { $0.name == item })?.id else {
                                    return
                                }
                                self.selectedGenre = item
                                self.viewModel.selectedGenres = id
                            } label: {
                                Text(item)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(self.selectedGenre == item ? .anipickSecondary : .textBlack)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(self.selectedGenre == item ? .anipickSecondary : .gray6)
                                    )
                            }
                            
                        }
                    }
                }
                .padding(20)
                .background(.white)
                
            } else if selectedTab == .type {
                ScrollView {
                    FlowLayout() {
                        ForEach(currentList, id: \.self) { item in
                            Button {
                                print("Type : \(item)")
                                viewModel.selectedType = item
                            } label: {
                                Text(item)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(viewModel.selectedType == item ? .anipickSecondary : .textBlack)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(viewModel.selectedType == item ? .anipickSecondary : .gray6)
                                    )
                            }
                            
                        }
                    }
                }
                .padding(20)
            }
            
            
            Spacer()
            
            HStack(spacing: 0) {
                
                Spacer()
                
                Button {
                    DLog("초기화버튼 탭 - 모든 장르 초기화")
                    self.viewModel.selectedAllClear = true
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    DLog("완료버튼 탭탭")
                    // TODO: 완료버튼을 눌렀을 때, sheet 닫히고 filter에 적용되도록 수정 -> view에 tag 보여지도록 수정
                    self.isPresentYearFilter.toggle()
                    viewModel.fetchInitFilteredExploreData()
                    if viewModel.selectedAllClear {
                        self.viewModel.allClearSelectedCategory()
                        self.viewModel.selectedAllClear = false
                    }
                    
                } label: {
                    Text("완료")
                        .frame(width: 60, height: 30)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                        .background(.anipickPrimary)
                        .cornerRadius(4)
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 20)
        .background(.white)
    }
    
    private func animationCell(item: Anime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            AnimeCommonCellWithTitle(imageUrl: item.coverImageUrl, width: nil, height: 162, title: item.title)
        }
        .buttonStyle(.plain)
    }
    
    private func headerView() -> some View {
        // MARK: - 상단 로고 및 searchBar
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(.aniPickLogoGreen)
                    .resizable()
                    .frame(width: 110, height: 22)
                
                Spacer()
                
                Button {
                    print("searchButton Tapped")
                } label: {
                    Image(.searchIconsGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .background(.gray5)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 9)
                .background(.gray7)
        }
    }
    
    private func getSortOptionView(sort: ExploreSortCategory) -> some View {
        return VStack(spacing: 0) {
            ForEach(ExploreSortCategory.allCases, id: \.self) { option in
                Button {
                    self.viewModel.selectedCategory = option
                    self.viewModel.tappedSortButton()
                } label: {
                    Text(option.title)
                        .customFontStyle(size: 14, color: .anipickBlack)
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

#Preview {
    AppDIContainer.makeExploreView()
}
