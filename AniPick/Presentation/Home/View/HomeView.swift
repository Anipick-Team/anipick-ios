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
            .padding(.top, 12)
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 24)
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    InstagramBannerView()

                    Spacer().frame(height: 36)

                    HStack(spacing: 0) {
                        Text("실시간 인기 애니메이션")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                        
                        Spacer()
                        
                        Button {
                            self.viewModel.moveToRankingView()
                        } label: {
                            Image(.chevronLeftGray)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            let animes = viewModel.trendingAnimes
                            ForEach(animes, id: \.self) { item in
                                self.animationCellWithRakingLabel(index: 1, anime: item) {
                                    DLog("실시간 인기 애니메이션 탭했을 때 이동이동")
                                    self.viewModel.moveToAnimeDetailView(animeId: item.animeId ?? 0)
                                }
                                .padding(.trailing, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                sectionDivider()
                
                if self.viewModel.recommendationAnimes.isEmpty {
                     Image("empty_recommendation")
                        .padding(.bottom, 24)
                } else {
                    let nickName = UserDefaultsManager.shared.getNickname()
                    if let title = viewModel.referenceAnimeTitle {
                        self.sectionView(
                            title: "\(title) 을 재밌게 보셨다면,\n이 작품들도 마음에 드실 거에요!",
                            items: viewModel.recommendationAnimes
                        ) {
                            viewModel.moveToRecommendationView(animeId: 0, animeTitle: viewModel.referenceAnimeTitle)
                            DLog("추천작 탭탭")
                        }
                        .padding(.bottom, 24)
                    } else {
                        self.sectionView(
                            title: "오늘의 추천작, \(nickName) 님의\n취향에 맞춰 준비했어요!",
                            items: viewModel.recommendationAnimes
                        ) {
                            viewModel.moveToRecommendationView(animeId: 0, animeTitle: viewModel.referenceAnimeTitle)
                            DLog("추천작 탭탭")
                        }
                        .padding(.bottom, 24)
                    }

                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("최근 리뷰")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                        
                        Spacer()
                        
                        Button {
                            DLog("최근 리뷰 탭탭")
                            viewModel.moveToRecentReviewView()
                        } label: {
                            Image(.chevronLeftGray)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            self.recentReviewCell()
                                .padding(.trailing, 12)
                            
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.gray7)
                
                Spacer().frame(height: 28)
                
                // TODO: 얘가 기본 default값 UI
                self.sectionView(title: "\(viewModel.seasonYearString)년도 \(viewModel.seasonString)분기 방영예정", items: viewModel.upcomingAnimes) {
                    self.viewModel.moveToExploreView(
                        season: self.viewModel.seasonString,
                        year: self.viewModel.seasonYearString
                    )
                }
                
                sectionDivider()
                
                // TODO: 닉네임 글자수가 너무 길 때, 닉네임을 말줄임 하는 것으로 viewModel에서 작업
                self.sectionView(title: "최근 찾아보신 \(viewModel.recommendationFirstTitle)과\n비슷한 작품이에요!", items: viewModel.recommendationSimilarAnimes) {
                    viewModel.moveToSimilarRecommendationView()
                }
                
                sectionDivider()
                
                self.sectionView(title: "공개 예정", items: viewModel.comingSoonAnimes) {
                    DLog("공개 예정 탭탭")
                    self.viewModel.moveToComingSoonView()
                }
            }
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
                await viewModel.getRecentsReviews()
                await viewModel.getUpComingSeason()
                await viewModel.getComingSoonSeason()
            }
        }
    }
    
    private func sectionView(title: String, items: [Anime], action: @escaping () -> Void) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.anipickBlack)
                
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
    
    private func sectionDivider() -> some View {
        return VStack(spacing: 0) {
            Spacer().frame(height: 32)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .background(.gray7)
            
            Spacer().frame(height: 28)
        }
        .ignoresSafeArea()
    }
    
    private func recentReviewCell() -> some View {
        return ForEach(viewModel.recentReviews, id: \.self) { item in
            Button {
                self.viewModel.moveToRecentReviewView()
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.animeTitle ?? "--")
                            .font(.system(size: 12))
                            .padding(.bottom, 7)
                            .lineLimit(1)
                        
                        Text(item.reviewContent ?? "--")
                            .frame(width: 197, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .font(.system(size: 16))
                            .padding(.bottom, 17)
                        
                        HStack(spacing: 0) {
                            Text(item.nickname ?? "--")
                                .lineLimit(1)
                            
                            Rectangle()
                                .frame(width: 1, height: 10)
                                .padding(.horizontal, 8)
                            
                            // TODO: 날짜 변환 필요
                            Text(item.createdAt ?? "--")
                        }
                        .font(.system(size: 12))
                        
                    }
                    .foregroundStyle(.anipickBlack)
                    .frame(width: 197, height: 112)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func animationCellWithRakingLabel(index: Int, anime: TrendingAnimes, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    AnimeImageCommonCell(
                        imageUrl: anime.coverImageUrl,
                        width: 128,
                        height: 174
                    )
                    
                    // 초록색 배경의 숫자 뱃지
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.green)
                            .frame(width: 36, height: 36)
                        
                        Text("\(anime.rank ?? 0)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .black))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(anime.title ?? "")
                    .customFontStyle(size: 16, color: .anipickBlack)
                    .frame(width: 128, height: 45, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.top, 6)
            }
        }
    }
    
    private func animationCell(anime: Anime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            AnimeCommonCellWithTitle(
                imageUrl: anime.coverImageUrl,
                width: 128,
                height: 174,
                title: anime.title
            )
        }
    }
}


#Preview {
    AppDIContainer.makeHomeView()
}
