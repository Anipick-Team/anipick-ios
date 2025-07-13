//
//  HomeView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct HomeView: View {
    @State private var nickName: String = "띵똥띵똥"
    @State private var recentAnimationName: String = "던전밥"
    
    @StateObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 상단 로고 및 searchBar
            HStack(spacing: 0) {
                Image(.aniPickLogoGreen)
                    .resizable()
                    .frame(width: 110, height: 22)
                
                Spacer()
                
                Button {
                    print("searchButton Tapped")
                    self.viewModel.moveToSearchView()
                } label: {
                    Image(.searchIconsGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 32)
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .foregroundStyle(.gray6)
                .padding(.horizontal, -20)
            
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("실시간 인기 애니메이션")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                        
                        Spacer()
                        
                        Button {
//                            print("실시간 인기 애니메이션 탭탭")
//                            Task {
//                                await viewModel.getTrendingAnimes()
//                            }
                        } label: {
                            Image(.chevronLeftGray)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 16)
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            let animes = viewModel.trendingAnimes
                            ForEach(animes, id: \.self) { item in
                                self.animationCellWithRakingLabel(index: 1, anime: item)
                                    .padding(.trailing, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                    }
                }
                .padding(.top, 36)
                
                
                sectionDivider()
                
                
                self.sectionView(title: "오늘의 추천작, \(nickName)님의\n취향에 맞춰 준비했어요!", items: [])
                    .padding(.bottom, 24)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("최근 리뷰")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.anipickBlack)
                        
                        Spacer()
                        
                        Button {
                            print("최근 리뷰 탭탭")
                        } label: {
                            Image(.chevronLeftGray)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 0) {
                            ForEach(0..<5) { _ in
                                self.recentReviewCell()
                                    .padding(.trailing, 12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.gray7)
                
                Spacer().frame(height: 28)
                
                // TODO: 얘가 기본 default값 UI
                self.sectionView(title: "25년도 3분기 방영예정", items: viewModel.upcomingAnimes?.animes ?? [])
                
                sectionDivider()
                
                // TODO: 닉네임 글자수가 너무 길 때, 닉네임을 말줄임 하는 것으로 viewModel에서 작업
                self.sectionView(title: "최근 찾아보신 \(recentAnimationName)과\n비슷한 작품이에요!", items: [])
                
                sectionDivider()
                
                self.sectionView(title: "공개 예정", items: viewModel.commingSoonAnimes)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DLog("accessToken - \(UserDefaultsManager.shared.getAccessToken())")
            DLog("refreshToken - \(UserDefaultsManager.shared.getRefreshToken())")
            Task {
                await viewModel.getTrendingAnimes()
                await viewModel.getRecentsReviews()
                await viewModel.getUpComingSeason()
                await viewModel.getComingSoonSeason()
                await viewModel.getComingSoonSeason()
            }
        }
    }
    
    private func sectionView(title: String, items: [Anime]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.anipickBlack)
                
                Spacer()
                
                Button {
                    print("\(title) 탭탭")
                } label: {
                    Image(.chevronLeftGray)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(items, id: \.self) { item in
                        self.animationCell(anime: item)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func sectionDivider() -> some View {
        return VStack(spacing: 0) {
            Spacer().frame(height: 52)
            
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
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.animeTitle)
                        .font(.system(size: 12))
                        .padding(.bottom, 7)
                    
                    Text(item.reviewContent)
                        .frame(width: 197, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .font(.system(size: 16))
                        .padding(.bottom, 17)
                    
                    HStack(spacing: 0) {
                        Text(item.nickname)
                            .lineLimit(1)
                        
                        Rectangle()
                            .frame(width: 1, height: 10)
                            .padding(.horizontal, 8)
                        
                        // TODO: 날짜 변환 필요
                        Text(item.createdAt)
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
    
    private func animationCellWithRakingLabel(index: Int, anime: TrendingAnimes) -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
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
                
                // 초록색 배경의 숫자 뱃지
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.green)
                        .frame(width: 36, height: 36)
                    
                    Text("1")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .black))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(anime.title)
                .foregroundStyle(.anipickBlack)
                .frame(width: 128, height: 45)
                .font(.system(size: 16))
                .lineLimit(2)
                .padding(.top, 6)
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
                //                RoundedRectangle(cornerRadius: 12)
                //                    .foregroundColor(Color.gray.opacity(0.2))
                //                    .frame(width: 128, height: 174)
                
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(anime.title ?? "-")
                .foregroundStyle(.anipickBlack)
                .frame(width: 128, height: 45)
                .font(.system(size: 16))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
}


#Preview {
    AppDIContainer.makeHomeView()
}
