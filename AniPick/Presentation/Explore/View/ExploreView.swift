//
//  ExploreView.swift
//  AniPick
//
//  Created by cho on 6/15/25.
//

import SwiftUI

enum ExploreFilterTab: String, CaseIterable, Identifiable {
    case yearQuarter = "년도/분기"
    case season = "분기"
    case genre = "장르"
    case type = "타입"

    var id: String { self.rawValue }
}

struct ExploreView: View {
    @StateObject var viewModel: ExploreViewModel
    @EnvironmentObject var appState: AppState
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var selectedTab: ExploreFilterTab = .yearQuarter
    @State private var isPresentYearFilter: Bool = false
    
    @State private var activeFilterTab: ExploreFilterTab? = nil   // NEW

    
    @State private var isPresentGenreFilter: Bool = false
    
    @State private var fromHomeupcoming: Bool = false
    
    @State private var tmpSelectedYear: String = ""
    @State private var tmpSelectedSeason: String = ""
    @State private var tmpSelectedGenreList: [String] = []
    @State private var tmpSelectedType: String = ""
    
    @State private var showFilterBar = true
    @State private var lastOffset: CGFloat = 0

    
    @State private var genreList: [String] = UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
    
    // UI체크용
    @State private var selectedGenre: String = ""
    @State private var selectedGenreListForUI: [String] = []
    @State private var sheetHeight: CGFloat = 400
    
    @State private var lastScrollOffset: CGFloat = 0
     @State private var currentScrollOffset: CGFloat = 0
    private let scrollThreshold: CGFloat = 10

    var currentList: [String] {
           switch selectedTab {
               // quator -> 분기는 1,2,3,4 분기로 나누어져있어서 따로 받아와서 처리 X
           case .yearQuarter: return UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
           case .genre: return UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
           case .type: return UserDefaultsManager.shared.getMetaDataForType()
           case .season: return ["전체 분기", "1분기", "2분기", "3분기", "4분기"]
           }
       }
    
    let quarterList = ["전체", "1", "2", "3", "4"]
    
    @State private var exploreRequestItem: ExploreReqeustItem? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                
                self.headerView()
                
                Spacer().frame(height: 16)
                
                if showFilterBar {
                    HStack(spacing: 0) {
                        self.filterCategoryButtonView(selectedTab: .yearQuarter)
                            .padding(.trailing, 8)
                        
                        self.filterCategoryButtonView(selectedTab: .genre)
                            .padding(.trailing, 8)
                        
                        self.filterCategoryButtonView(selectedTab: .type)
                        
                    }
                    .padding(.horizontal, 20)
                    
                }
                
                if viewModel.selectedTagList.isEmpty == false {
                    self.selectredCategoryView()
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Button {
                        DLog("인기순 탭탭")
                        self.viewModel.isShowSortOptionView.toggle()
                    } label: {
                        Text(self.viewModel.selectedCategory.title)
                            .customFontStyle(size: 14, color: .gray8)
                            .padding(.trailing, 20)
                    }
                }
                .padding(.vertical, 20)
                
                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { newValue in
                                let diff = newValue - currentScrollOffset
                                
                                // 최소 threshold 이상 움직였을 때만 반응
                                if abs(diff) > scrollThreshold {
                                    if diff < 0 {  // 아래로 스크롤
                                      //  DLog("⬇️ 스크롤 다운 - 필터 숨기기")
                                      //  withAnimation(.easeInOut(duration: 0.2)) {
                                            showFilterBar = false
                                       // }
                                    } else {  // 위로 스크롤
                                   //     DLog("⬆️ 스크롤 업 - 필터 보이기")
                                     //   withAnimation(.easeInOut(duration: 0.2)) {
                                            showFilterBar = true
                                    //    }
                                    }
                                }
                                
                                currentScrollOffset = newValue
                            }
                            .preference(key: ScrollOffsetKey.self,
                                        value: geo.frame(in: .global).minY)
                    }
                    .frame(height: 0)
//                    GeometryReader { geo in
//                        Color.clear
//                            .preference(key: ScrollOffsetPreferenceKey.self,
//                                        value: geo.frame(in: .global).minY)
//                    }
//                    .frame(height: 1)
                    
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.exploreItems, id: \.animeId) { item in
                                animationCell(item: item) {
                                    self.viewModel.tappedAnime(animeId: item.animeId ?? 0)
                                }
                                .onAppear {
                                    if item == viewModel.exploreItems.last {
                                        DLog("explore 데이터 확인 - \(item) -- \(String(describing: viewModel.exploreItems.last))")
                                        viewModel.fetchFiletedExploreData()
                                    }
                                }
                            }
                        }
                }
                .coordinateSpace(name: "explore")
                .padding(.horizontal, 20)
            }
            .onChange(of: selectedTab) { newValue in
                DLog("선택된 Tab - \(newValue)")
                if newValue == .yearQuarter || newValue == .genre || newValue == .type {
                    self.isPresentYearFilter = true
                }
            }
            .sheet(isPresented: $isPresentYearFilter) {
                filterSelectedHalfModalView()
                    .id(selectedTab)
                    .presentationDetents([.height(self.sheetHeight)])
                
            }
            .background(Color.white)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                self.applyIncomingFilterIfNeeded()
                viewModel.fetchFiletedExploreData()
            }
            .onChange(of: AppDIContainer.appState.pendingExploreFilter) { _ in
                DLog("appState onChange 감지")
                applyIncomingFilterIfNeeded()
            }
            if viewModel.isShowSortOptionView {
                getSortOptionView(sort: viewModel.selectedCategory)
                    .padding(.trailing, 20)
                    .offset(y: 160)
                    .zIndex(2)
                    .animation(.easeInOut, value: viewModel.isShowSortOptionView)
            }
        }
        .onPreferenceChange(ScrollOffsetKey.self) { newValue in

        }
//        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { y in
//            DLog("스크롤 Y offset: \(y)")
//            handleScroll(yOffset: y)
//        }
    }
    
    func handleScroll(yOffset: CGFloat) {
        DLog("yoffset - \(yOffset)")
        if yOffset < -50 {
            showFilterBar = false
        } else {
            showFilterBar = true
        }
    }
    
    private func applyIncomingFilterIfNeeded() {
        guard let f = AppDIContainer.appState.consumeExploreFilter() else { return }

          // 예: 태그로 반영
          if let y = f.year, !y.isEmpty {
              let item = ExploreSelectedTag(category: .yearQuarter, value: y)
              self.insertTagIfNotExist(item)
          }
        
          if let s = f.season, !s.isEmpty {
              let item = ExploreSelectedTag(category: .season, value: s)
              self.insertTagIfNotExist(item)
          }

          // 데이터 로드
          viewModel.fetchFiletedExploreData()
      }
    
    private func filterCategoryButtonView(selectedTab: ExploreFilterTab) -> some View {
      //  let isSelectedFilter = self.viewModel.checkFilterColored(selectedTab: selectedTab)
        let isSelectedFilter = self.viewModel.selectedTagList.contains { $0.category == selectedTab }
        return VStack(spacing: 0) {
            Button {
                DLog("\(selectedTab.rawValue) tapped")
                self.selectedTab = selectedTab
                self.activeFilterTab = selectedTab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isPresentYearFilter = true
                }
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

    private func selectredCategoryView() -> some View {
        return
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.gray5)
                
                Spacer().frame(height: 12)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(self.viewModel.selectedTagList, id: \.self) { item in
                            HStack(spacing: 0) {
                                let postFix = item.value == "전체 분기" ? "" : "분기"
                                if item.category == .season {
                                    Text("\(item.value)\(postFix)")
                                        .padding(.trailing, 4)
                                        .customFontStyle(size: 14, color: .anipickPrimary)
                                } else {
                                    Text(item.value)
                                        .padding(.trailing, 4)
                                        .customFontStyle(size: 14, color: .anipickPrimary)
                                }
                                
                                Button {
                                    DLog("viewModel에서 해당 값 삭제삭제")
                                    self.viewModel.removeTagView(item: item)

                                    if item.category == .genre {
                                        if let index = self.selectedGenreListForUI.firstIndex(of: item.value) {
                                            self.selectedGenreListForUI.remove(at: index)
                                        }
                                    }
                                    
                                    if item.category == .yearQuarter {
                                        self.viewModel.selectedTagList.removeAll { $0.category == .yearQuarter || $0.category == .season }
                                    }
                                    self.viewModel.fetchInitFilteredExploreData()

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

    
    private func filterSelectedHalfModalView () -> some View {
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
                self.makeYearAndSeasonView()
            } else if selectedTab == .genre {
                self.makeGenreView()
            } else if selectedTab == .type {
                self.makeTypeView()
            }
            
            
            Spacer()
            
            HStack(spacing: 0) {
                
                Spacer()
                
                Button {
                    DLog("초기화버튼 탭 - 모든 장르 초기화")
                    self.viewModel.selectedAllClear = true
                    if viewModel.selectedAllClear {
                        self.viewModel.allClearSelectedCategory()
                        self.viewModel.selectedAllClear = false
                        self.selectedGenreListForUI.removeAll()
                    }
                    self.tmpSelectedType = ""
                    self.tmpSelectedYear = ""
                    self.tmpSelectedSeason = ""

                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    DLog("완료버튼 탭탭")
                    if tmpSelectedYear.isEmpty == false {
                        let item = ExploreSelectedTag(category: .yearQuarter, value: tmpSelectedYear)
                        self.insertTagReplacingCategory(item)
                    //    self.insertTagIfNotExist(item)
                    }
                    
                    if tmpSelectedSeason.isEmpty == false {
                        let item = ExploreSelectedTag(category: .season, value: tmpSelectedSeason)
                        self.insertTagReplacingCategory(item)
                      //  self.insertTagIfNotExist(item)
                    }
                    
                    if tmpSelectedGenreList.isEmpty == false {
                        for item in tmpSelectedGenreList {
                            let genreItem = ExploreSelectedTag(category: .genre, value: item)
                            self.insertTagIfNotExist(genreItem)
                        }
                       
                    }
                    
                    if tmpSelectedType.isEmpty == false {
                        let item = ExploreSelectedTag(category: .type, value: tmpSelectedType)
                        self.insertTagReplacingCategory(item)
                    }
                    
                //    self.tmpSelectedYear = ""
                 //   self.tmpSelectedSeason = ""
                 //   self.tmpSelectedType = ""
                    self.tmpSelectedGenreList.removeAll()
                    
                    DLog("tagList 확인 - \(self.viewModel.selectedTagList)")
                    self.isPresentYearFilter.toggle()
                    self.viewModel.exploreItems.removeAll()
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
        .onAppear {
            if self.tmpSelectedSeason == "" {
                self.tmpSelectedSeason = quarterList.first ?? "전체 분기"
            }
            
            if selectedTab == .yearQuarter {
                if self.tmpSelectedYear == "" {
                    self.tmpSelectedYear = currentList.first ?? ""
                }
            }
        }
    }
    
   private func insertTagIfNotExist(_ tag: ExploreSelectedTag) {
        if !viewModel.selectedTagList.contains(where: { $0.category == tag.category && $0.value == tag.value }) {
            viewModel.selectedTagList.insert(tag, at: 0)
        }
    }

    private func insertTagReplacingCategory(_ tag: ExploreSelectedTag) {
        // 1️⃣ 같은 category 가진 항목이 있으면 모두 제거
        viewModel.selectedTagList.removeAll { $0.category == tag.category }

        // 2️⃣ 새 tag 추가
        viewModel.selectedTagList.insert(tag, at: 0)
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
                    DLog("searchButton Tapped")
                    self.viewModel.moveToSearchView()
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

// MARK: UI Component
extension ExploreView {
    private func makeYearAndSeasonView() -> some View {
        return HStack(spacing: 0) {
            Picker("", selection: self.$tmpSelectedYear) {
                ForEach(currentList, id: \.self) {
                    Text($0)
                        .customFontStyle(size: 14, color: .anipickBlack)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("", selection: self.$tmpSelectedSeason) {
                ForEach(quarterList, id: \.self) {
                    Text($0)
                        .customFontStyle(size: 14, color: .anipickBlack)
                }
            }
            .pickerStyle(.wheel)
        }
    }
    
    private func makeGenreView() -> some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                
                Button {
                    self.viewModel.isToggleAllGenreCondition.toggle()
                  //  self.selectedGenreListForUI.removeAll()
               //     self.viewModel.tappedAllCondition()
                } label: {
                    Text("모든 조건 일치")
                        .customFontStyle(size: 14, color: .anipickBlack)
                        .padding(.trailing, 4)
                    
                    Image(self.viewModel.isToggleAllGenreCondition ? .grayToggleOn : .grayToggleOff)
                        .resizable()
                        .frame(width: 40, height: 24)
                }
            }
            .padding(.bottom, 12)
            .padding(.trailing, 8)
            
            
            ScrollView(showsIndicators: false) {
                FlowLayout() {
                    ForEach(currentList, id: \.self) { item in
                        Button {
                            if self.tmpSelectedGenreList.contains(item) {
                                self.tmpSelectedGenreList.removeAll { $0 == item }
                                self.selectedGenreListForUI.removeAll { $0 == item }
                            } else {
                                self.tmpSelectedGenreList.append(item)
                                self.selectedGenreListForUI.append(item)
                            }
                            
                            DLog("check - \(tmpSelectedGenreList)")
                        } label: {
                            let isSelected = selectedGenreListForUI.contains(item)
                            
                            Text(item)
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .foregroundStyle(isSelected ? .anipickSecondary : .textBlack)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? .anipickSecondary : .gray6)
                                )
                        }
                        
                    }
                }
            }
        }
        .padding(20)
        .background(.white)
    }
    
    private func makeTypeView() -> some View {
        return ScrollView(showsIndicators: false) {
            FlowLayout() {
                ForEach(currentList, id: \.self) { item in
                    Button {
                        DLog("Type : \(item)")
                        self.tmpSelectedType = item
                        // viewModel.selectedType = item
                    } label: {
                        Text(item)
                            .font(.system(size: 14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .foregroundStyle(self.tmpSelectedType == item ? .anipickSecondary : .textBlack)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(self.tmpSelectedType == item ? .anipickSecondary : .gray6)
                            )
                    }
                    
                }
            }
        }
        .padding(20)
    }
}
#Preview {
    AppDIContainer.makeExploreView()
}
