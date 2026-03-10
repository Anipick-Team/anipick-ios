//
//  PreferenceSelectionView.swift
//  AniPick
//
//  Created by cho on 5/3/25.
//

import SwiftUI

struct PreferenceSelectionView: View {
    @StateObject var viewModel: PreferenceSelectionViewModel
    
    let quarterList = ["전체", "1", "2", "3", "4"]
    @State private var selectedList: [String] = []
    @State private var isShowStarRatingView: Bool = false
    @State private var isHeaderHidden: Bool = false
    
    var currentList: [String] {
        switch selectedTab {
        case .yearQuarter: return UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
        case .genre: return UserDefaultsManager.shared.getMetaDataForGenres().map { $0.name }
        }
    }
    
    @State private var selectedTab: FilterTab = .genre
    @State private var sheetHeight: CGFloat = 400

    //@State private var selectedQuarter: String = ""

    @State private var starRating: Int = 0
    @State private var showStarRatingView: Bool = false

    @State private var currentScrollOffset: CGFloat = 0
    @State private var filterBarLocked = false
    private let scrollThreshold: CGFloat = 30
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Spacer().frame(height: 34)
            
            Text("좋아하는 애니메이션을 선택하면\n취향에 맞는 작품을 추천할게요")
                .customFontStyle(size: 20, color: .anipickBlack, weight: .semibold)
                .padding(.bottom, 8)
            
            Text("좋아하는 애니메이션을 골라 주세요.")
                .customFontStyle(size: 14, color: .anipickSecondary)
            
            Spacer().frame(height: 40)
            
            
            if !isHeaderHidden {
                Text("평가한 작품 \(viewModel.storedRatedAnimeList.count)")
                    .customFontStyle(size: 14, color: viewModel.storedRatedAnimeList.count > 0 ? .point : .gray6)
                
                Spacer().frame(height: 16)
                
                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 16, height: 16)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                    
                    TextField(
                        "",
                        text: $viewModel.searchBarString,
                        prompt: Text("검색")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textGray)
                    )
                    .padding(.horizontal, 4)
                    .background(Color.gray5)
                    .foregroundColor(.anipickBlack)
                    
                    Spacer()
                    
                    Button {
                        DLog("searchBar all clear 버튼")
                        self.viewModel.tappedAllClearButton()
                    } label: {
                        Image(.allClearButton)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 11)
                .background(Color.gray5)
                .cornerRadius(8)
                
                Spacer().frame(height: 16)
                
                HStack(spacing: 0) {
                    Button {
                        DLog("년도 탭탭")
                        self.selectedTab = .yearQuarter
                        self.viewModel.isPresentModelView.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(self.viewModel.selectedYear.isEmpty ? "년도" : self.viewModel.selectedYear)
                                .font(.system(size: 16))
                                .foregroundStyle(self.viewModel.selectedYear.isEmpty ? .textBlack : .anipickSecondary)
                                .padding(.trailing, 10)
                            
                            Image(self.viewModel.selectedYear.isEmpty ? .chevronDownGray : .chevronDownBlue)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(self.viewModel.selectedYear.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                        )
                        .foregroundStyle(.anipickBlack)
                    }
                    .padding(.trailing, 8)
                    
                    
                    Button {
                        DLog("분기 탭탭")
                        self.selectedTab = .yearQuarter
                        self.viewModel.isPresentModelView.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(self.viewModel.selectedQuarter.isEmpty ? "분기" : "\(self.viewModel.selectedQuarter)분기")
                                .font(.system(size: 16))
                                .foregroundStyle(self.viewModel.selectedQuarter.isEmpty ? .textBlack : .anipickSecondary)
                                .padding(.trailing, 10)
                            
                            Image(self.viewModel.selectedQuarter.isEmpty ? .chevronDownGray : .chevronDownBlue)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(self.viewModel.selectedQuarter.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                        )
                        .foregroundStyle(.anipickBlack)
                    }
                    .padding(.trailing, 8)
                    
                    
                    
                    Button {
                        DLog("장르 탭탭")
                        self.selectedTab = .genre
                        self.viewModel.isPresentModelView.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(self.viewModel.selectedGenre.isEmpty ? "장르" : self.viewModel.selectedGenre)
                                .font(.system(size: 16))
                                .foregroundStyle(self.viewModel.selectedGenre.isEmpty ? .textBlack : .anipickSecondary)
                                .padding(.trailing, 10)
                            
                            Image(self.viewModel.selectedGenre.isEmpty ? .chevronDownGray : .chevronDownBlue)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(self.viewModel.selectedGenre.isEmpty ? .gray5 : .anipickSecondary, lineWidth: 1)
                        )
                        .foregroundStyle(.anipickBlack)
                    }
                    
                }
                
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundStyle(.gray5)
                    .padding(.horizontal, -20)
                    .padding(.vertical, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { newValue in
                            let diff = newValue - currentScrollOffset
                            currentScrollOffset = newValue

                            guard !filterBarLocked else { return }

                            if abs(diff) > scrollThreshold {
                                if diff < 0 && !isHeaderHidden {
                                    filterBarLocked = true
                                    withAnimation(.easeInOut(duration: 0.05)) { isHeaderHidden = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        filterBarLocked = false
                                    }
                                } else if diff > 0 && isHeaderHidden {
                                    filterBarLocked = true
                                    withAnimation(.easeInOut(duration: 0.05)) { isHeaderHidden = false }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        filterBarLocked = false
                                    }
                                }
                            }
                        }
                }
                .frame(height: 0)

                LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.animeList.enumerated()), id: \.element.self) { index, value in
                            self.animationCell(anime: value, showStarRating: !viewModel.isRatedAnime(animeId: value.animeId ?? 0)) {
                                self.viewModel.isShowRatedAnime(animeId: value.animeId ?? 0)
                            }
                            .onAppear {
                                // 페이징
                                if value.animeId == viewModel.animeList.last?.animeId {
                                    self.viewModel.fetchRecommendAnime()
                                }
                            }
                            
                            if viewModel.isRatedAnime(animeId: value.animeId ?? 0) {
                                StarRatingView() { rating in
                                    self.viewModel.tappedEachRatedAnime(animeId: value.animeId ?? 0, rating: rating)
                                    self.viewModel.isShowRatedAnime(animeId: value.animeId ?? 0)
                                }
                            }
                        }
                        
                    }
//                    ForEach(viewModel.animeList, id: \.self) { value in
//                        // TODO: 평가한 애니메이션의 경우, showStarRating 보여야함
//                        //  let isShowStar = viewModel.isRatedAnime(animeId: value.animeId ?? 0)
//                        self.animationCell(anime: value, showStarRating: !viewModel.isRatedAnime(animeId: value.animeId ?? 0)) {
//                            self.viewModel.isShowRatedAnime(animeId: value.animeId ?? 0)
//                        }
//                        .onAppear {
//                            if value.animeId == viewModel.animeList.last?.animeId {
//                                self.viewModel.fetchRecommendAnime()
//                            }
//                        }
//                        // TODO: 각 애니메이션 별 star 표시하도록 적용
//                        if viewModel.isRatedAnime(animeId: value.animeId ?? 0) {
//                            StarRatingView() { rating in
//                                self.viewModel.tappedEachRatedAnime(animeId: value.animeId ?? 0, rating: rating)
//                                self.viewModel.isShowRatedAnime(animeId: value.animeId ?? 0)
//                            }
//                        }
//                    }
                }
            
            .coordinateSpace(name: "scroll") // ⭐️ 중요
//            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
//                DLog("scroll 확인 - \(value)")
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    self.isHeaderHidden = value < -50   // 위로 50px 이상 올리면 숨김
//                }
//            }
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray5)
                .padding(.horizontal, -20)
                .padding(.vertical, 20)
            
            // 항상 활성화
            FullWidthButton(isEnable: .constant(true), buttonText: "완료") {
                DLog("완료 버튼 탭탭")
                self.viewModel.tappedDoneRatedAnime()
                self.viewModel.moveToMainView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
        .sheet(isPresented: $viewModel.isPresentModelView) {
            filterSelectedHalfModalView()
                .presentationDetents([.height(self.sheetHeight)])
                .onHeightChange { newHeight in
                    self.sheetHeight = newHeight
                }
        }
        .onAppear {
            self.viewModel.fetchMataData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                   viewModel.fetchRecommendAnime()
               }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
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
                
                Spacer()
                
                
                Button {
                    print("닫기 탭탭")
                    self.viewModel.tappedModelView()
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
                let yearList = UserDefaultsManager.shared.getMetaDataForSeasonYear().map { String($0) }
                HStack(spacing: 0) {
                    Picker("", selection: $viewModel.selectedYear) {
                        ForEach(yearList, id: \.self) {
                            Text($0)
                                .customFontStyle(size: 18, color: .anipickSecondary)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("", selection: $viewModel.selectedQuarter) {
                        ForEach(quarterList, id: \.self) {
                            Text($0)
                                .customFontStyle(size: 18, color: .anipickSecondary)
                                .customFontStyle(size: 18, color: .anipickSecondary)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            } else {
                
                ScrollView(showsIndicators: false) {
                    FlowLayout() {
                        ForEach(currentList, id: \.self) { item in
                            Button {
                                DLog("장르 탭 : \(item)")
                                self.viewModel.selectedGenre(name: item)
                                self.viewModel.selectedGenre = item
                            } label: {
                                Text(item)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(self.viewModel.selectedGenre == item ? .anipickSecondary : .textBlack)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(self.viewModel.selectedGenre == item ? .anipickSecondary : .gray6)
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
                    DLog("초기화버튼 탭")
                    self.viewModel.selectedYear = ""
                    self.viewModel.selectedGenre = ""
                    self.viewModel.selectedQuarter = ""
                    self.viewModel.selectedGenreId = nil
                    self.viewModel.lastId = nil
                } label: {
                    Text("초기화")
                        .font(.system(size: 14))
                        .foregroundStyle(.textGray)
                }
                
                Spacer().frame(width: 16)
                
                Button {
                    DLog("완료버튼")
                    self.viewModel.lastId = nil
                    self.viewModel.tappedModelView()
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
    
    private func animationCell(
        anime: AnimePreference,
        showStarRating: Bool,
        action: @escaping () -> Void
    ) -> some View {
        var eachStarRating: Double = 0.0
        
        return VStack(spacing: 0) {
            Button {
                DLog("취향 애니메이션 탭탭")
                action()
            } label: {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                // 회색 배경 정사각형
                                if let url = anime.coverImageUrl {
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .empty:
                                            // 로딩 중 placeholder
                                            Image(.animeThumbnail)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 133, height: 89)
                                                .clipped()
                                            
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 133, height: 89)
                                                .clipped()
                                            
                                        case .failure:
                                            // 실패 시 fallback
                                            Image(.animeThumbnail)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 133, height: 89)
                                                .clipped()
                                            
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.trailing, 20)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(anime.title ?? "--")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.textBlack)
                                        .padding(.bottom, 4)
                                        .padding(.top, 4)
                                        .padding(.trailing, 2)
                                    
                                    Spacer()
                                    
                                    if viewModel.isRatedDoneAnime(animeId: anime.animeId ?? 0) {
                                        Button {
                                            DLog("회원가입에서의 평가 취소 버튼 tapped")
                                            self.viewModel.removeRatedAnime(animeId: anime.animeId ?? 0)
                                        } label: {
                                            Text("평가취소")
                                                .frame(width: 56, height: 27)
                                                .customFontStyle(size: 12, color: .background)
                                                .background(Color.anipickPrimary)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .padding(.bottom, 4)
                                
                                if let genres = anime.genres {
                                    Text(genres.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.textGray)
                                }
                                
                                Spacer()
                                
                                if viewModel.isRatedDoneAnime(animeId: anime.animeId ?? 0) {
                                    let index = self.viewModel.storedRatedAnimeList.firstIndex(where: { $0.animeId == anime.animeId ?? 0 })
                                    var currentStar = self.viewModel.storedRatedAnimeList[index ?? 0].rating
                                    
                                    StarRatingComponentView(
                                        starRating: currentStar,
                                        fontSize: 13,
                                        fontColor: .point,
                                        starSize: 18) { star in
                                            self.viewModel.tappedEachRatedAnime(
                                                animeId: anime.animeId ?? 0,
                                                rating: star
                                            )
                                        }
                                    .padding(.bottom, 4)
                                }
                                
                            }
                            
                            
                            Spacer()
                            
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray7, lineWidth: 1)
                            .background(Color.white.cornerRadius(8))
                            .frame(maxWidth: .infinity)
                    )
                }
            }
            
        }
    }
}

enum FilterTab: String, CaseIterable {
    case yearQuarter = "년도/분기"
    case genre = "장르"
}
#Preview {
    AppDIContainer.makePreferenceSelectionView()
}
