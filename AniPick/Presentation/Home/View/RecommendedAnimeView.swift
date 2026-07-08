//
//  RecommendedAnimeView.swift
//  AniPick
//
//  Created by cho on 1/20/26.
//

import SwiftUI

struct RecommendedAnimeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: RecommendViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        DLog("뒤로가기 버튼 탭탭")
                        dismiss()
                    } label: {
                        Image(.chevronLeft)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 8)
                
                Spacer()
                
                Text("추천 애니메이션")
                    .customFontStyle(size: 18, color: .anipickBlack)
                
                Spacer()
            }
            
            Spacer().frame(height: 30)
            
            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
            
            Spacer().frame(height: 24)
            
            ScrollView(showsIndicators: false) {
                
                ZStack {
                    // 배경
                    Rectangle()
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                    
                    VStack {
                        HStack {
                            let nickname = UserDefaultsManager.shared.getNickname()
                            if let title = viewModel.animeTitle {
                                Text("\(title) 을 재밌게 보셨다면,\n이 작품들도 마음에 드실거에요!")
                                    .customFontStyle(size: 20, color: .gray5, weight: .bold)
                                    .padding(.top, 12)
                                    .padding(.leading, 24)
                                Spacer()
                            } else {
                                Text("오늘의 추천작, \(nickname) 님의\n취향에 맞춰 준비했어요!")
                                    .customFontStyle(size: 20, color: .gray5, weight: .bold)
                                    .padding(.top, 12)
                                    .padding(.leading, 24)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(.cloud)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .frame(height: 151)
                .padding(.bottom, 20)
                
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.recommendationAnimes, id: \.self) { item in
                        animationCell(item: item)
                            .onAppear {
                                self.viewModel.getNextPage(lastAnimeId: item.animeId ?? 0)
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchRecommendationAnime()
        }
    }
    
    private func animationCell(item: Anime) -> some View {
        return Button {
            self.viewModel.tappedAnimeDetail(animeId: item.animeId ?? 0)
        } label: {
            AnimeCommonCellWithTitle(imageUrl: item.coverImageUrl, width: nil, height: 162, title: item.title)
        }
    }
}

#Preview {
    AppDIContainer.makeRecommendationView(animeId: 11111)
}
