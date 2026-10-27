//
//  HomeView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct HomeView: View {
    @State private var nickname: String = ""
    @StateObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 상단 로고 및 searchBar
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
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(Color.white)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(.gray6)
            }
            // Figma effect `header`: X 0, Y 2, Blur 12, #000000 20%
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
            .zIndex(1)  // 그림자가 아래 스크롤 영역에 가려지지 않도록

            ScrollView(showsIndicators: false) {
                VStack(spacing: 100) {
                    VStack(spacing: 0) {
                        InstagramBannerView()
                            .padding(.top, 20)
                            .padding(.bottom, 28)

                        self.sectionHeader(title: Text(verbatim: "실시간 인기 애니메이션")) {
                            self.viewModel.moveToRankingView()
                        }
                        
                        Spacer().frame(height: 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                let animes = viewModel.trendingAnimes
                                ForEach(animes, id: \.self) { item in
                                    Button {
                                        DLog("실시간 인기 애니메이션 탭했을 때 이동이동")
                                        self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                                    } label: {
                                        HomeAnimeCard(
                                            imageUrl: item.coverImageUrl,
                                            title: item.title,
                                            rank: item.rank
                                        )
                                    }
                                    .padding(.trailing, 12)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if self.viewModel.recommendationAnimes.isEmpty {
                         Image("empty_recommendation")
                    } else {
                        let nickName = UserDefaultsManager.shared.getNickname()
                        if let title = viewModel.referenceAnimeTitle {
                            self.sectionView(
                                title: self.highlightedTitle(title, " 을 재밌게 보셨다면,\n이 작품들도 마음에 드실 거에요!"),
                                items: viewModel.recommendationAnimes
                            ) {
                                viewModel.moveToRecommendationView(animeId: 0, animeTitle: viewModel.referenceAnimeTitle)
                                DLog("추천작 탭탭")
                            }
                        } else {
                            self.sectionView(
                                title: self.highlightedTitle(prefix: "오늘의 추천작, ", nickName, " 님의\n취향에 맞춰 준비했어요!"),
                                items: viewModel.recommendationAnimes
                            ) {
                                viewModel.moveToRecommendationView(animeId: 0, animeTitle: viewModel.referenceAnimeTitle)
                                DLog("추천작 탭탭")
                            }
                        }

                    }

                    weekdayNewAnimeSection()

                    VStack(alignment: .leading, spacing: 0) {
                        self.sectionHeader(title: Text(verbatim: "최근 리뷰")) {
                            DLog("최근 리뷰 탭탭")
                            viewModel.moveToRecentReviewView()
                        }
                        .padding(.bottom, 16)
                        
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                self.recentReviewCell()
                                    .padding(.trailing, 12)
                                
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // TODO: 얘가 기본 default값 UI
                    self.sectionView(title: self.highlightedTitle("\(viewModel.seasonYearString)년도 \(viewModel.seasonString)분기", " 방영예정"), items: viewModel.upcomingAnimes) {
                        self.viewModel.moveToExploreView(
                            season: self.viewModel.seasonString,
                            year: self.viewModel.seasonYearString
                        )
                    }
                    
                    // TODO: 닉네임 글자수가 너무 길 때, 닉네임을 말줄임 하는 것으로 viewModel에서 작업
                    if viewModel.hasRecentSimilarAnime {
                        self.sectionView(title: self.highlightedTitle(prefix: "최근 찾아보신 ", viewModel.recommendationFirstTitle, "과\n비슷한 작품이에요!"), items: viewModel.recommendationSimilarAnimes) {
                            viewModel.moveToSimilarRecommendationView()
                        }
                    } else {
                        Image("empty_recent_viewed")
                            .accessibilityLabel("아직 찾아본 애니가 없어요. 다양한 애니를 탐색해 보세요!")
                    }
                    
                    self.sectionView(title: Text(verbatim: "공개 예정"), items: viewModel.comingSoonAnimes) {
                        DLog("공개 예정 탭탭")
                        self.viewModel.moveToComingSoonView()
                    }
                }
            }
            .background(.gray7)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
        .onAppear {
            DLog("accessToken - \(UserDefaultsManager.shared.getAccessToken())")
            DLog("refreshToken - \(UserDefaultsManager.shared.getRefreshToken())")
            self.nickname = UserDefaultsManager.shared.getNickname()
            //viewModel.getTrendingAnimes()
            if UserDefaultsManager.shared.getLastVisitedAnimeId() != 0 {
                viewModel.fetchRecommendationAnimeWithAnimeId()
            } else {
                viewModel.fetchRecommendationAnime()
            }
            viewModel.fetchSimilarAnime()
            viewModel.fetchRecommendationAnime()
            Task {
                await viewModel.getTrendingAnimes()
                await viewModel.getWeekdayNewAnimes()
                await viewModel.getRecentsReviews()
                await viewModel.getUpComingSeason()
                await viewModel.getComingSoonSeason()
            }
        }
    }
    
    /// 섹션 제목 줄 (Figma `H3`: Bold 18, 줄 높이 140%)
    private func sectionHeader(title: Text, action: @escaping () -> Void) -> some View {
        // 두 줄 제목에서도 > 버튼이 첫 줄에 맞도록 상단 정렬
        return HStack(alignment: .top, spacing: 0) {
            title
                .customFontStyle(size: 18, color: .anipickBlack, weight: .bold)
                .lineSpacing(4)  // 줄 높이 25.2pt(140%)에 맞춘 근사값
                .padding(.vertical, 2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                action()
            } label: {
                Image(.chevronLeftGray)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
    }

    /// 섹션 제목에서 `highlight` 부분만 primary 색으로 칠한다
    private func highlightedTitle(prefix: String = "", _ highlight: String, _ suffix: String) -> Text {
        return Text("\(Text(verbatim: prefix))\(Text(verbatim: highlight).foregroundColor(.primaryColor))\(Text(verbatim: suffix))")
    }

    private func sectionView(title: Text, items: [Anime], action: @escaping () -> Void) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            self.sectionHeader(title: title, action: action)
                .padding(.bottom, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        self.animationCell(anime: item) {
                            self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func weekdayNewAnimeSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: Text(verbatim: "요일별 신작")) {
                viewModel.moveToWeekdayNewAnimeView()
            }
            .padding(.bottom, 20)

            // 칩 7개를 좌우 끝에 맞춰 균등 배치 (Figma space-between)
            HStack(spacing: 0) {
                ForEach(WeekdayNewAnimeDay.allCases) { day in
                    let isSelected = viewModel.selectedWeekday == day
                    Button {
                        Task { await viewModel.selectWeekday(day) }
                    } label: {
                        Text(day.title)
                            .customFontStyle(
                                size: 18,
                                color: isSelected ? .white : .textGray,
                                weight: .bold
                            )
                            .frame(width: 45, height: 45)
                            .background(isSelected ? Color.primaryColor : Color.gray6)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if day != WeekdayNewAnimeDay.allCases.last {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.weekdayNewAnimes, id: \.self) { item in
                        animationCell(anime: item) {
                            viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func recentReviewCell() -> some View {
        return ForEach(viewModel.recentReviews, id: \.self) { item in
            Button {
                self.viewModel.moveToRecentReviewView()
            } label: {
                // Figma `review`: 229x136, 위아래 12·좌우 16, 테두리 1px #DFDFDF
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.animeTitle ?? "--")
                            .customFontStyle(size: 12, color: .textGray, weight: .medium)
                            .lineLimit(1)

                        Text(item.reviewContent ?? "--")
                            .customFontStyle(size: 16, color: .anipickBlack, weight: .medium)
                            .lineSpacing(3)  // 줄 높이 22.4pt(140%)에 맞춘 근사값
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .frame(height: 50, alignment: .topLeading)
                    }

                    Spacer(minLength: 16)

                    // 닉네임은 날짜를 뺀 남은 폭(약 117)에서 말줄임
                    HStack(spacing: 8) {
                        Text(item.nickname ?? "--")
                            .lineLimit(1)

                        Rectangle()
                            .frame(width: 1, height: 10)

                        Text(self.reviewDateText(item.createdAt))
                            .fixedSize()
                    }
                    .customFontStyle(size: 12, color: .textGray, weight: .medium)
                }
                .frame(width: 197, height: 112, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray6, lineWidth: 1)
                }
            }
        }
    }

    /// 서버 날짜 앞부분의 `yyyy-MM-dd`·`yyyy.MM.dd`를 `yyyy.MM.dd`로 맞춘다. 다른 형식이면 그대로 둔다.
    private func reviewDateText(_ raw: String?) -> String {
        guard let raw else { return "--" }
        let prefix = String(raw.prefix(10))
        let isDate = prefix.range(of: #"^\d{4}[-.]\d{2}[-.]\d{2}$"#, options: .regularExpression) != nil
        return isDate ? prefix.replacingOccurrences(of: "-", with: ".") : raw
    }
    
    private func animationCell(anime: Anime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            HomeAnimeCard(imageUrl: anime.coverImageUrl, title: anime.title)
        }
    }
}

struct WeekdayNewAnimeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: WeekdayNewAnimeViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .frame(height: 9)
                .foregroundStyle(.gray7)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    weekdayPicker

                    HStack(spacing: 0) {
                        Spacer()
                        Menu {
                            ForEach(WeekdayNewAnimeSort.allCases) { sort in
                                Button(sort.title) {
                                    Task { await viewModel.select(sort: sort) }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSort.title)
                                    .customFontStyle(size: 14, color: .gray8)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.gray8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if viewModel.animes.isEmpty {
                        Text("해당 요일에 등록된 신작이 없어요.")
                            .customFontStyle(size: 14, color: .gray8)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                            ForEach(viewModel.animes, id: \.self) { item in
                                Button {
                                    viewModel.tappedAnime(item)
                                } label: {
                                    AnimeCommonCellWithTitle(
                                        imageUrl: item.coverImageUrl,
                                        width: nil,
                                        height: 162,
                                        title: item.title
                                    )
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    Task { await viewModel.loadMoreIfNeeded(item: item) }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .simultaneousGesture(daySwipeGesture)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    /// 가로 방향이 우세한 스와이프만 요일 이동으로 처리해 세로 스크롤과 겹치지 않게 한다.
    private var daySwipeGesture: some Gesture {
        return DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }
                Task {
                    if dx < 0 {
                        await viewModel.selectNextDay()
                    } else {
                        await viewModel.selectPreviousDay()
                    }
                }
            }
    }

    private var header: some View {
        ZStack {
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            Text("요일별 신작")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .semibold)
        }
        .frame(height: 58)
        .background(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
    }

    private var weekdayPicker: some View {
        HStack(spacing: 8) {
            ForEach(WeekdayNewAnimeDay.allCases) { day in
                Button {
                    Task { await viewModel.select(day: day) }
                } label: {
                    Text(day.title)
                        .customFontStyle(
                            size: 14,
                            color: viewModel.selectedDay == day ? .white : .gray8,
                            weight: .semibold
                        )
                        .frame(width: 44, height: 44)
                        .background(viewModel.selectedDay == day ? Color.primaryColor : Color.gray7)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 38)
    }
}


#Preview {
    AppDIContainer.makeHomeView()
}
