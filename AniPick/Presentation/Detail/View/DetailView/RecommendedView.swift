//
//  RecommendedView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct RecommendedView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: RecommendedViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "함께 볼만한 작품") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .frame(height: 151)
                    .background(Color.black)
                    .cornerRadius(8)
                
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("'\(viewModel.animeTitle)'와\n 함께보기 좋은 작품")
                            .customFontStyle(size: 24, color: .gray7, weight: .bold)
                            .padding(.top, 20)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    Spacer()
                }
                
                Image(.recommendView)
                    .padding(.trailing, 20)
                
            }
            .frame(height: 151)
            
            Spacer().frame(height: 24)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(self.viewModel.recommendedAnimeList, id: \.self) { item in
                        AnimeCommonCellWithTitle(
                            imageUrl: item.coverImageUrl,
                            width: nil,
                            height: 162,
                            title: item.title
                        )
                        .onAppear {
                            if item == viewModel.recommendedAnimeList.last {
                                DLog("recommended 데이터 확인 - \(item) -- \(String(describing: viewModel.recommendedAnimeList.last))")
                                viewModel.fetchRecommendationAnimeInfo()
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .navigationBarBackButtonHidden()
        .onAppear {
            self.viewModel.fetchRecommendationAnimeInfo()
        }
    }
    
    private func animationCell() -> some View {
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 162)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("착각하는 공방주 영풍파티의 전 잡어쩌구어쩌구")
               // .frame(width: 128, height: 45)
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
    
}

